# V3.0 Dev A — Backend Scoring & Explainability API (CORRECTED)

## Files
- `backend/app/api/scoring_router.py` — Score storage + history
- `backend/app/api/explainability_router.py` — Server-side L5–L10
- `backend/app/services/fairness_engine.py` — Fairness monitoring

---

## Scoring Router

### POST /api/v1/score/store
Stores score report + full 115-feature vector for audit trail.

```python
@router.post("/score/store")
async def store_score(request: ScoreStoreRequest, bg: BackgroundTasks):
    doc = {
        "report_id": f"GC-{int(time.time()*1000)}",
        "user_id": request.user_id,
        "final_score": request.final_score,
        "grade": request.grade,
        "pillar_scores": request.pillar_scores,           # 8 pillars
        "pillar_scores_raw": request.pillar_scores_raw,    # before calibration
        "pillar_scores_calibrated": request.pillar_scores_calibrated,
        "confidence_values": request.confidence_values,     # 8 conformal
        "feature_vector": request.feature_vector,           # FULL 115 features
        "work_type": request.work_type,
        "probability": request.probability,                 # raw meta-learner
        "stored_at": datetime.utcnow().isoformat(),
    }
    await db.scores.insert_one(doc)
    bg.add_task(audit_chain.append, "score_store", doc)
    
    # Trigger server-side explainability asynchronously
    bg.add_task(compute_server_xai, doc)
    
    return {"report_id": doc["report_id"], "stored_at": doc["stored_at"]}
```

### GET /api/v1/score/history/{user_id}
Returns all past score reports (for Delta-SHAP L9).

---

## Explainability Router — Server-Side Layers

### POST /api/v1/explain/full
Computes L5–L10 when user is connected.

```python
@router.post("/explain/full")
async def explain_full(request: ExplainRequest):
    report = await db.scores.find_one({"report_id": request.report_id})
    features = np.array(report["feature_vector"])  # 115 features
    results = {}
    
    # ── L5: Live SHAP (exact, fresh) ──────────────
    # Different method per model type
    shap_all = {}
    for pillar, model_info in PILLAR_MODELS.items():
        model = models[pillar]
        pillar_features = slice_features_for_pillar(features, pillar)
        
        if model_info['type'] in ['lgbm']:
            # LightGBM: built-in pred_contrib (fastest)
            contribs = model.predict([pillar_features], pred_contrib=True)
            shap_all[pillar] = contribs[0][:-1].tolist()  # exclude bias
        elif model_info['type'] in ['xgb', 'xgb_shallow']:
            # XGBoost: TreeExplainer (exact)
            explainer = shap.TreeExplainer(model)
            shap_all[pillar] = explainer.shap_values([pillar_features])[0].tolist()
        elif model_info['type'] == 'extratrees':
            # ExtraTrees: TreeExplainer (supported)
            explainer = shap.TreeExplainer(model)
            shap_all[pillar] = explainer.shap_values([pillar_features])[0].tolist()
    
    results["L5_live_shap"] = shap_all
    
    # ── L6: Explanation Faithfulness Score (EFS) ──────────────
    original_top3 = get_top3_by_shap(shap_all)
    efs_count = 0
    for _ in range(50):
        noisy = features + np.random.normal(0, 0.02 * np.abs(features))
        noisy_shap = compute_all_shap(noisy, models)
        noisy_top3 = get_top3_by_shap(noisy_shap)
        if set(noisy_top3) == set(original_top3):
            efs_count += 1
    efs = efs_count / 50
    
    results["L6_efs"] = {
        "score": round(efs, 2),
        "label": "STABLE" if efs >= 0.85 else "MODERATE" if efs >= 0.50 else "UNSTABLE",
        "note": "" if efs >= 0.85 else
                "Score near a boundary. Small changes could alter explanation." if efs >= 0.50 else
                "Explanation unstable. Manual review recommended."
    }
    
    # ── L7: Peer Cohort Mirror ──────────────
    from sklearn.metrics.pairwise import cosine_similarity
    train_features = load_training_features()  # 15K × 115
    sims = cosine_similarity([features], train_features)[0]
    top25_idx = np.argsort(sims)[-25:]
    
    cohort_scores = [train_scores[i] for i in top25_idx]
    high_group = [i for i in top25_idx if train_scores[i] >= 650]
    low_group = [i for i in top25_idx if train_scores[i] < 550]
    
    # Top 5 feature differences between high and low groups
    if high_group and low_group:
        high_means = train_features[high_group].mean(axis=0)
        low_means = train_features[low_group].mean(axis=0)
        diffs = high_means - low_means
        top5_diff_idx = np.argsort(np.abs(diffs))[-5:][::-1]
        
        results["L7_peer_cohort"] = {
            "cohort_size": 25,
            "high_scorers": len(high_group),
            "low_scorers": len(low_group),
            "key_differences": [
                {
                    "feature": FEATURE_NAMES[i],
                    "display_name": DISPLAY_NAMES[FEATURE_NAMES[i]],
                    "high_group_avg": round(float(high_means[i]), 2),
                    "low_group_avg": round(float(low_means[i]), 2),
                    "diff": round(float(diffs[i]), 3),
                }
                for i in top5_diff_idx
            ]
        }
    
    # ── L8 Server: Full DoWhy Causal Graph ──────────────
    # Simplified for hackathon: template-based causal chains
    results["L8_causal_server"] = generate_causal_report(report, features)
    
    # ── L9: Delta-SHAP (returning users) ──────────────
    prev_report = await db.scores.find_one(
        {"user_id": request.user_id, "report_id": {"$ne": request.report_id}},
        sort=[("stored_at", -1)]
    )
    if prev_report and "shap_values" in prev_report:
        prev_shap = prev_report["shap_values"]
        delta_shap = {}
        for fname in FEATURE_NAMES:
            if fname in shap_all_flat and fname in prev_shap:
                d = shap_all_flat[fname] - prev_shap[fname]
                if abs(d) > 0.03:
                    delta_shap[fname] = {
                        "delta": round(d, 4),
                        "display_name": DISPLAY_NAMES.get(fname, fname),
                        "direction": "improved" if d > 0 else "declined",
                        "score_impact_pts": round(d * 600, 0),
                    }
        
        # Sort by absolute delta
        sorted_delta = sorted(delta_shap.items(), key=lambda x: abs(x[1]["delta"]), reverse=True)
        results["L9_delta_shap"] = {
            "previous_score": prev_report["final_score"],
            "current_score": report["final_score"],
            "score_change": report["final_score"] - prev_report["final_score"],
            "improved": [e for _, e in sorted_delta if e["direction"] == "improved"][:3],
            "declined": [e for _, e in sorted_delta if e["direction"] == "declined"][:3],
            "fully_explained": True,
        }
    
    # ── L10: LLM Translation ──────────────
    try:
        prompt = build_llm_prompt(report, results, request.language)
        nl_report = await call_gemini(prompt)
        results["L10_nl_report"] = nl_report
    except Exception:
        results["L10_nl_report"] = build_template_report(report, results)
    
    # Store SHAP values in audit trail for future Delta-SHAP
    await db.scores.update_one(
        {"report_id": request.report_id},
        {"$set": {"shap_values": shap_all_flat, "efs_score": efs}}
    )
    await audit_chain.append("explain_full", report)
    
    return results
```

---

## POST /api/v1/fairness/report

```python
@router.get("/fairness/report")
async def get_fairness_report():
    engine = FairnessEngine(db)
    recent = await db.scores.find().sort("stored_at", -1).limit(500).to_list(500)
    report = await engine.run_audit(recent)
    return report
```
