#!/usr/bin/env python3
"""
Definitive check for GAPs 2-6 (GAP 1 excluded per user request)
Uses correct patterns matching actual implementation.
"""
import re
from pathlib import Path

STEP_FILES = {
    i: next(iter(Path("app/lib/features/score/flow").glob(f"step{i}_*.dart")), None)
    for i in range(3, 10)
}

def read(path):
    return path.read_text(encoding='utf-8') if path and path.exists() else ""

# ─────────────────────────────────────────────────────────────
# GAP 2: Validation loading overlay (VerificationPhaseMixin)
# ─────────────────────────────────────────────────────────────
def check_gap2():
    print("\n── GAP 2: Validation Loading States ──────────────────────")
    overlay = Path("app/lib/shared/widgets/feedback/verification_phase_overlay.dart")
    overlay_ok = overlay.exists() and "Validating inputs" in read(overlay) and "Cross-checking identity" in read(overlay)
    print(f"  {'✅' if overlay_ok else '❌'} VerificationPhaseOverlay widget with cycling messages")

    steps_ok = True
    for step in [4, 5, 6, 7, 8, 9]:
        c = read(STEP_FILES[step])
        ok = ("with VerificationPhaseMixin" in c and
              "showVerificationPhase()" in c and
              "dismissVerificationPhase()" in c)
        print(f"  {'✅' if ok else '❌'} Step {step}: VerificationPhaseMixin wired")
        if not ok:
            steps_ok = False

    resolved = overlay_ok and steps_ok
    print(f"\n  GAP 2: {'✅ RESOLVED' if resolved else '❌ NOT RESOLVED'}")
    return resolved

# ─────────────────────────────────────────────────────────────
# GAP 3: Downstream step reset when earlier step re-verified
# ─────────────────────────────────────────────────────────────
def check_gap3():
    print("\n── GAP 3: Downstream Step Reset Logic ────────────────────")
    provider = Path("app/lib/state/step_status_provider.dart")
    c = read(provider)

    has_was_verified   = "wasAlreadyVerified" in c
    has_reset_loop     = bool(re.search(r"for\s*\(int\s+i\s*=\s*step\s*\+\s*1", c))
    has_notstarted_set = "notStarted" in c and "updated[i]" in c

    print(f"  {'✅' if has_was_verified else '❌'} wasAlreadyVerified guard in setStatus()")
    print(f"  {'✅' if has_reset_loop else '❌'} Loop: for i = step+1 to 9")
    print(f"  {'✅' if has_notstarted_set else '❌'} Sets downstream steps to notStarted")

    resolved = has_was_verified and has_reset_loop and has_notstarted_set
    print(f"\n  GAP 3: {'✅ RESOLVED' if resolved else '❌ NOT RESOLVED'}")
    return resolved

# ─────────────────────────────────────────────────────────────
# GAP 4: Bank statement merge (not replace) on second upload
# ─────────────────────────────────────────────────────────────
def check_gap4():
    print("\n── GAP 4: Bank Statement Merge Logic ─────────────────────")
    c = read(STEP_FILES[3])

    has_merge_comment  = "GAP 4" in c or "MERGE" in c
    has_txn_append     = bool(re.search(r"_transactions\s*=\s*\[\.\.\._transactions,\s*\.\.\.", c))
    has_credit_merge   = bool(re.search(r"_monthlyCredits\[i\]\s*\+=", c))
    has_merge_toast    = "Statement Merged" in c

    print(f"  {'✅' if has_merge_comment else '❌'} Merge comment / GAP 4 marker")
    print(f"  {'✅' if has_txn_append else '❌'} Transaction append: [..._transactions, ...newTxns]")
    print(f"  {'✅' if has_credit_merge else '❌'} Monthly credits summed for overlapping months")
    print(f"  {'✅' if has_merge_toast else '❌'} Toast: 'Statement Merged'")

    resolved = has_txn_append and has_credit_merge
    print(f"\n  GAP 4: {'✅ RESOLVED' if resolved else '❌ NOT RESOLVED'}")
    return resolved

# ─────────────────────────────────────────────────────────────
# GAP 5: Consecutive month validation for utility bills
# ─────────────────────────────────────────────────────────────
def check_gap5():
    print("\n── GAP 5: Consecutive Month Validation ───────────────────")
    c = read(STEP_FILES[4])

    # final bool bug fixed
    final_bug_gone = not bool(re.search(r"final\s+bool\s+_\w+Uploaded\s*=\s*false", c))
    # mutable upload booleans
    has_mutable = bool(re.search(r"^\s*bool\s+_elecUploaded\s*=\s*false", c, re.MULTILINE))
    # wired to onExtracted
    all_wired = all(f"_{t}Uploaded = true" in c
                    for t in ["elec", "water", "gas", "mobile", "internet", "rent"])
    # upload required check in _submit
    has_upload_guard = "_hasElectricity && !_elecUploaded" in c
    # insufficient bills warning
    has_insufficient_warn = "insufficientBills" in c
    # demo autofill sets count=6
    has_demo_count = "_elecUploadCount = 6" in c

    print(f"  {'✅' if final_bug_gone else '❌'} final bool bug fixed (upload booleans mutable)")
    print(f"  {'✅' if has_mutable else '❌'} bool _elecUploaded = false (mutable)")
    print(f"  {'✅' if all_wired else '❌'} All 6 upload booleans wired to onExtracted")
    print(f"  {'✅' if has_upload_guard else '❌'} Upload required guard in _submit()")
    print(f"  {'✅' if has_insufficient_warn else '❌'} Warning when < 6 months uploaded")
    print(f"  {'✅' if has_demo_count else '❌'} Demo autofill sets uploadCount=6")

    resolved = final_bug_gone and has_mutable and all_wired and has_upload_guard and has_insufficient_warn
    print(f"\n  GAP 5: {'✅ RESOLVED' if resolved else '❌ NOT RESOLVED'}")
    return resolved

# ─────────────────────────────────────────────────────────────
# GAP 6: Backend API calls in Steps 5-9
# ─────────────────────────────────────────────────────────────
def check_gap6():
    print("\n── GAP 6: Backend API Calls in Steps 5-9 ─────────────────")
    expected = {
        5: ["verifyVehicle", "getGigHistory"],
        6: ["verifyEshram", "verifyUdyam", "verifyPmsym"],
        7: ["verifyInsurance"],
        8: ["getGstFilingHistory", "verifyItr"],
        9: ["checkLoans"],
    }
    all_ok = True
    for step, apis in expected.items():
        c = read(STEP_FILES[step])
        missing = [a for a in apis if f"api.{a}(" not in c]
        ok = len(missing) == 0
        print(f"  {'✅' if ok else '❌'} Step {step}: {', '.join(apis)}"
              + (f"  ← MISSING: {missing}" if missing else ""))
        if not ok:
            all_ok = False

    print(f"\n  GAP 6: {'✅ RESOLVED' if all_ok else '❌ NOT RESOLVED'}")
    return all_ok

# ─────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────
def main():
    print("=" * 60)
    print("GIGCREDIT — GAPS 2-6 DEFINITIVE CHECK")
    print("(GAP 1 excluded per user request)")
    print("=" * 60)

    results = {
        "GAP 2 (Validation Loading)":   check_gap2(),
        "GAP 3 (Downstream Reset)":     check_gap3(),
        "GAP 4 (Bank Merge)":           check_gap4(),
        "GAP 5 (Consecutive Months)":   check_gap5(),
        "GAP 6 (Backend APIs)":         check_gap6(),
    }

    print("\n" + "=" * 60)
    print("FINAL RESULT")
    print("=" * 60)
    for name, ok in results.items():
        print(f"  {'✅' if ok else '❌'} {name}: {'RESOLVED' if ok else 'NOT RESOLVED'}")

    total = sum(results.values())
    print(f"\n  {total}/5 gaps resolved (GAP 1 skipped)")
    if total == 5:
        print("\n  🎉 ALL GAPS 2-6 RESOLVED AND VERIFIED!")
    else:
        remaining = [k for k, v in results.items() if not v]
        print(f"\n  ⚠️  Still needs work: {', '.join(remaining)}")
    return 0 if total == 5 else 1

if __name__ == "__main__":
    exit(main())
