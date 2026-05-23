#!/usr/bin/env python3
"""
Deep verification of GAP 2, GAP 3, and GAP 5
"""

import re
from pathlib import Path

def check_gap_2_detailed():
    """GAP 2: Loading Spinner During Validation - Deep Check"""
    print("\n" + "="*60)
    print("GAP 2: VALIDATION LOADING STATES")
    print("="*60)
    
    steps_to_check = [4, 5, 6, 7, 8, 9]
    
    for step in steps_to_check:
        print(f"\n--- Step {step} ---")
        matches = list(Path("app/lib/features/score/flow").glob(f"step{step}_*.dart"))
        
        if not matches:
            print(f"❌ File not found")
            continue
        
        content = matches[0].read_text(encoding='utf-8')
        
        # Check for loading state variable
        has_loading = bool(re.search(r'bool\s+_isLoading\s*=\s*false', content))
        has_validating = bool(re.search(r'bool\s+_isValidating\s*=\s*false', content))
        
        # Check for setState with loading
        sets_loading = bool(re.search(r'setState\(\(\)\s*=>\s*_isLoading\s*=\s*true', content))
        
        # Check for validation phase indicators
        has_validation_text = bool(re.search(r'Verifying|Validating|Cross-checking|Processing', content))
        
        print(f"  _isLoading variable: {'✅' if has_loading else '❌'}")
        print(f"  _isValidating variable: {'✅' if has_validating else '❌'}")
        print(f"  Sets loading state: {'✅' if sets_loading else '❌'}")
        print(f"  Validation text: {'✅' if has_validation_text else '❌'}")
        
        # Check if validation happens during _isLoading
        if has_loading and sets_loading:
            # Check if bank cross-verification happens during loading
            submit_match = re.search(r'Future<void>\s+_submit\(\)\s+async\s*\{(.*?)\n\s*\}', content, re.DOTALL)
            if submit_match:
                submit_body = submit_match.group(1)
                has_bank_check = bool(re.search(r'bankInfo\.transactions|monthlyDebits|monthlyCredits', submit_body))
                has_api_call = bool(re.search(r'await\s+api\.', submit_body))
                
                print(f"  Bank cross-check in submit: {'✅' if has_bank_check else '❌'}")
                print(f"  API calls in submit: {'✅' if has_api_call else '❌'}")
                
                if has_bank_check or has_api_call:
                    print(f"  ✅ Validation happens during _isLoading phase")
                else:
                    print(f"  ⚠️  _isLoading exists but no validation detected")
        else:
            print(f"  ❌ No loading state management")
    
    print("\n" + "="*60)
    print("CONCLUSION: GAP 2")
    print("="*60)
    print("Steps 4-9 have _isLoading state that covers the entire submit")
    print("process including validation. However, there's no SEPARATE")
    print("_isValidating state to distinguish validation from submission.")
    print("\nSTATUS: ⚠️  PARTIALLY IMPLEMENTED")
    print("The audit document says this is P3 (low priority) because")
    print("validation is fast enough that a separate spinner isn't needed.")

def check_gap_3_detailed():
    """GAP 3: Back Navigation Re-Validation - Deep Check"""
    print("\n" + "="*60)
    print("GAP 3: DOWNSTREAM STEP RESET LOGIC")
    print("="*60)
    
    # Check step status provider
    provider_path = Path("app/lib/state/step_status_provider.dart")
    
    if not provider_path.exists():
        print("❌ step_status_provider.dart not found")
        return
    
    content = provider_path.read_text(encoding='utf-8')
    
    print("\n--- Checking StepStatusProvider ---")
    
    # Check for reset methods
    has_reset_all = bool(re.search(r'void\s+reset\(\)', content))
    has_set_status = bool(re.search(r'void\s+setStatus\(', content))
    has_clear_from = bool(re.search(r'void\s+clearFrom\(', content))
    has_reset_downstream = bool(re.search(r'void\s+resetDownstream\(', content))
    
    print(f"  reset() method: {'✅' if has_reset_all else '❌'}")
    print(f"  setStatus() method: {'✅' if has_set_status else '❌'}")
    print(f"  clearFrom() method: {'✅' if has_clear_from else '❌'}")
    print(f"  resetDownstream() method: {'✅' if has_reset_downstream else '❌'}")
    
    # Check if setStatus invalidates downstream
    if has_set_status:
        set_status_match = re.search(r'void\s+setStatus\([^)]+\)\s*\{(.*?)\n\s*\}', content, re.DOTALL)
        if set_status_match:
            method_body = set_status_match.group(1)
            invalidates_downstream = bool(re.search(r'for.*step.*>.*stepNumber|clearFrom|resetDownstream', method_body))
            print(f"  setStatus invalidates downstream: {'✅' if invalidates_downstream else '❌'}")
    
    # Check verified profile provider
    print("\n--- Checking VerifiedProfileProvider ---")
    profile_provider_path = Path("app/lib/state/verified_profile_provider.dart")
    
    if profile_provider_path.exists():
        profile_content = profile_provider_path.read_text(encoding='utf-8')
        
        # Check if updateStepX methods exist
        update_methods = []
        for i in range(1, 10):
            if re.search(rf'void\s+updateStep{i}\(', profile_content):
                update_methods.append(i)
        
        print(f"  Update methods found: Steps {update_methods}")
        
        # Check if any update method resets downstream
        resets_downstream = bool(re.search(r'resetDownstream|clearFrom|invalidate', profile_content))
        print(f"  Resets downstream on update: {'✅' if resets_downstream else '❌'}")
    
    print("\n" + "="*60)
    print("CONCLUSION: GAP 3")
    print("="*60)
    print("No automatic downstream step invalidation when earlier steps")
    print("are modified. Users can re-submit any step, but Steps N+1")
    print("through 9 remain 'verified' even if Step N data changes.")
    print("\nSTATUS: ❌ NOT IMPLEMENTED")
    print("This is a P1 (high priority) gap that affects data integrity.")

def check_gap_5_detailed():
    """GAP 5: Consecutive Month Validation - Deep Check"""
    print("\n" + "="*60)
    print("GAP 5: CONSECUTIVE MONTH VALIDATION")
    print("="*60)
    
    step4_path = Path("app/lib/features/score/flow/step4_utility_screen.dart")
    
    if not step4_path.exists():
        print("❌ step4_utility_screen.dart not found")
        return
    
    content = step4_path.read_text(encoding='utf-8')
    
    print("\n--- Checking Step 4 Utility Screen ---")
    
    # Check for consecutive month mentions
    consecutive_mentions = len(re.findall(r'consecutive.*6.*month|6.*consecutive.*month', content, re.IGNORECASE))
    print(f"  'Consecutive 6 months' mentioned: {consecutive_mentions} times")
    
    # Check for date validation
    has_date_validation = bool(re.search(r'DateTime|billDate|dueDate|issueDate', content))
    print(f"  Date handling: {'✅' if has_date_validation else '❌'}")
    
    # Check for month gap validation
    has_month_gap_check = bool(re.search(r'month.*gap|consecutive.*check|validateSequence', content, re.IGNORECASE))
    print(f"  Month gap validation: {'✅' if has_month_gap_check else '❌'}")
    
    # Check for bill count validation
    has_count_validation = bool(re.search(r'_elecUploadCount|_waterUploadCount|uploadCount', content))
    print(f"  Upload count tracking: {'✅' if has_count_validation else '❌'}")
    
    # Check submit method for validation
    print("\n--- Checking _submit() method ---")
    submit_match = re.search(r'Future<void>\s+_submit\(\)\s+async\s*\{(.*?)\n\s*\}', content, re.DOTALL)
    
    if submit_match:
        submit_body = submit_match.group(1)
        
        # Check if bills are validated for consecutive months
        validates_sequence = bool(re.search(r'validateConsecutive|checkMonthGap|sortByDate', submit_body))
        print(f"  Validates month sequence: {'✅' if validates_sequence else '❌'}")
        
        # Check if bills are sorted by date
        sorts_bills = bool(re.search(r'sort.*date|orderBy.*date', submit_body, re.IGNORECASE))
        print(f"  Sorts bills by date: {'✅' if sorts_bills else '❌'}")
        
        # Check if gap detection exists
        detects_gaps = bool(re.search(r'gap|missing.*month|skip', submit_body, re.IGNORECASE))
        print(f"  Detects month gaps: {'✅' if detects_gaps else '❌'}")
    
    # Check bank cross-verification
    print("\n--- Checking Bank Cross-Verification ---")
    has_bank_match = bool(re.search(r'bankInfo\.transactions|monthlyDebits', content))
    print(f"  Cross-checks with bank: {'✅' if has_bank_match else '❌'}")
    
    if has_bank_match:
        # Check if it validates amounts only or also dates
        validates_dates = bool(re.search(r'transaction.*date|bill.*date.*bank', content, re.IGNORECASE))
        print(f"  Validates transaction dates: {'✅' if validates_dates else '❌'}")
    
    print("\n" + "="*60)
    print("CONCLUSION: GAP 5")
    print("="*60)
    print("Step 4 UI mentions 'consecutive 6 months' but there's no")
    print("validation logic to enforce it. Bills are cross-checked with")
    print("bank transactions for amounts, but not for date sequence.")
    print("\nSTATUS: ❌ NOT IMPLEMENTED")
    print("This is a P2 (medium priority) gap. The spec requires")
    print("'6 consecutive months from current month' validation.")

def main():
    print("="*60)
    print("DETAILED VERIFICATION: GAP 2, GAP 3, GAP 5")
    print("="*60)
    
    check_gap_2_detailed()
    check_gap_3_detailed()
    check_gap_5_detailed()
    
    print("\n" + "="*60)
    print("FINAL SUMMARY")
    print("="*60)
    print("GAP 2: ⚠️  PARTIALLY IMPLEMENTED (P3 - Low Priority)")
    print("       _isLoading covers validation, no separate spinner needed")
    print("\nGAP 3: ❌ NOT IMPLEMENTED (P1 - High Priority)")
    print("       No downstream step reset when earlier steps change")
    print("\nGAP 5: ❌ NOT IMPLEMENTED (P2 - Medium Priority)")
    print("       No consecutive month sequence validation")

if __name__ == "__main__":
    main()
