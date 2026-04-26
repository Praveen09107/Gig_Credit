# ================================================================================
# GIGCREDIT — GIT WORKFLOW AND MERGE PROTOCOL
# Document 03 | Version 2.0 | planning_new
# ================================================================================

## 1. WHY THIS DOCUMENT EXISTS

In the previous attempt, git confusion caused:
- Files appearing to be pulled but actually missing
- Merge conflicts destroying work
- Wrong branches being pushed to
- No clear ownership of what's on which branch
- Version mismatches between Dev A and Dev B

This document establishes an **idiot-proof git workflow** for beginners.

---

## 2. REPOSITORY SETUP

### 2.1 Single Monorepo

Repository name: `gig-credit`
Hosted on: GitHub (private repository)
Both devs have push access.

### 2.2 Branch Structure

```
main                    ← Production-ready (updated only at integration gates)
│
├── develop             ← Integration branch (both devs merge here)
│   │
│   ├── dev-a/backend   ← Dev A's backend work
│   ├── dev-a/ml        ← Dev A's ML pipeline work
│   ├── dev-a/exports   ← Dev A's model export work
│   │
│   ├── dev-b/ui        ← Dev B's UI/UX work
│   ├── dev-b/logic     ← Dev B's on-device logic work
│   └── dev-b/scoring   ← Dev B's scoring integration work
```

### 2.3 Branch Rules

| Branch     | Who can push | When updated                    |
|-----------|-------------|----------------------------------|
| `main`     | NOBODY directly | Only via PR from `develop` at gates |
| `develop`  | Both via PR  | At every integration checkpoint  |
| `dev-a/*`  | Dev A only   | Freely, multiple times per day   |
| `dev-b/*`  | Dev B only   | Freely, multiple times per day   |

---

## 3. DAILY GIT WORKFLOW

### 3.1 Starting Your Day

```bash
# ALWAYS start with these commands
git checkout develop
git pull origin develop
git checkout dev-a/backend   # or dev-b/ui, whatever branch you're on
git merge develop            # get latest changes from other dev
```

### 3.2 While Working

```bash
# Commit frequently (every 30-60 minutes)
git add .
git commit -m "feat(backend): implement aadhaar verification endpoint"

# Push your branch to remote every few commits
git push origin dev-a/backend
```

### 3.3 Commit Message Format

```
type(scope): description

Types: feat, fix, refactor, test, docs, chore
Scope: backend, ml, ui, scoring, contracts, demo
```

Examples:
```
feat(backend): add /gov/pan/verify endpoint
feat(ui): build Step 2 identity verification screen
fix(scoring): correct NaN handling in feature sanitizer
test(backend): add unit tests for HMAC validation
docs(contracts): update api_contract.json with insurance endpoint
chore(ml): add requirements.txt for training pipeline
```

### 3.4 End of Day

```bash
# Always push your work at end of day
git add .
git commit -m "chore: end of day checkpoint"
git push origin dev-a/backend
```

---

## 4. MERGING TO DEVELOP

### 4.1 When to Merge

Merge to `develop` when:
- A feature is COMPLETE and TESTED locally
- You've reached an integration checkpoint (see doc 04)
- You need the other dev to test your work

### 4.2 How to Merge (Step by Step)

```bash
# Step 1: Make sure your branch is up to date
git checkout dev-a/backend
git push origin dev-a/backend

# Step 2: Switch to develop and pull latest
git checkout develop
git pull origin develop

# Step 3: Merge your branch into develop
git merge dev-a/backend

# Step 4: If conflicts → STOP → call the other dev → resolve together
# If no conflicts → continue

# Step 5: Push develop
git push origin develop

# Step 6: Notify other dev
# "MERGED: dev-a/backend → develop. Backend verification APIs ready."
```

### 4.3 If Merge Conflict Occurs

```bash
# DO NOT PANIC. DO NOT FORCE PUSH.

# Step 1: See what files conflict
git status

# Step 2: Open conflicted files and look for <<<<<<< markers
# Step 3: Call the other dev and resolve together
# Step 4: After fixing:
git add <fixed-files>
git commit -m "merge: resolve conflict in <files>"
git push origin develop
```

### 4.4 The GOLDEN RULE

> **NEVER use `git push --force` on `develop` or `main`.**
> **NEVER.** If something goes wrong, ask for help instead.

---

## 5. PREVENTING "FILES MISSING AFTER PULL"

This was a major issue in the previous attempt. Here's how to prevent it:

### 5.1 Always Verify After Pull

```bash
git pull origin develop

# IMMEDIATELY verify key files exist:
ls backend/app/main.py
ls app/lib/main.dart
ls contracts/api_contract.json

# If any file is missing → something went wrong
# Check: git log --oneline -5  (see recent commits)
# Check: git diff HEAD~1  (see what changed)
```

### 5.2 Large Files (ML Models)

ML model files (`.pkl`, `.bin`, `.dart` exports) can be large.
- Track them in git normally (they're text/small binary)
- `.dart` files from m2cgen are pure text — no issue
- `.json` config files are small — no issue
- If any file is >50MB → use Git LFS

### 5.3 .gitignore

```gitignore
# Python
__pycache__/
*.pyc
.env
venv/
*.egg-info/

# Flutter
app/.dart_tool/
app/.packages
app/build/
app/.flutter-plugins

# IDE
.idea/
.vscode/
*.swp

# OS
.DS_Store
Thumbs.db

# Temporary
*.tmp
*.log

# Never ignore these:
# app/assets/config/*.json
# app/lib/scoring/models/*.dart
# contracts/*.json
# demo_data/**
```

---

## 6. INTEGRATION CHECKPOINT MERGE PROTOCOL

At each integration checkpoint (see doc 04):

```bash
# Both devs do this:

# 1. Push your current work
git add . && git commit -m "gate: integration checkpoint N" && git push

# 2. Merge to develop
git checkout develop
git pull origin develop
git merge dev-a/backend  # (or dev-b/ui)
git push origin develop

# 3. Other dev pulls develop
git checkout develop
git pull origin develop
git merge develop  # into their feature branch

# 4. Both verify the full project compiles
cd app && flutter pub get && flutter analyze
cd backend && pip install -r requirements.txt && python -c "from app.main import app"

# 5. Run smoke test together
# See doc 04 for specific smoke test per checkpoint

# 6. If all passes → merge develop → main
git checkout main
git merge develop
git push origin main
git tag -a vN.0 -m "Integration Checkpoint N"
git push origin --tags
```

---

## 7. EMERGENCY RECOVERY

### 7.1 "I broke develop"

```bash
# Find the last good commit
git log --oneline develop

# Reset develop to last good commit
git checkout develop
git reset --hard <last-good-commit-hash>
git push origin develop --force-with-lease  # ONLY on develop, ONLY in emergency
```

### 7.2 "I lost my local changes"

```bash
# Check git reflog (shows ALL recent actions)
git reflog

# Find the commit hash of your lost work
git checkout <hash>
# Create a recovery branch
git checkout -b recovery/my-lost-work
```

### 7.3 "Merge went wrong"

```bash
# Undo the last merge (if not yet pushed)
git merge --abort     # if merge is in progress
git reset --hard HEAD~1  # if merge was committed but not pushed
```

---

## 8. PRE-FLIGHT CHECKLIST (Before Every Push)

```
□ All files I changed are staged (git status shows no untracked important files)
□ I'm on the correct branch (git branch shows my branch highlighted)
□ I committed with a descriptive message
□ My code compiles locally (flutter analyze / python -c "import app")
□ I'm NOT accidentally pushing to main or develop directly
□ I notified the other dev about what I'm pushing
```
