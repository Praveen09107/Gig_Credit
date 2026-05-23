#!/usr/bin/env python3
"""
Verify the status of all gaps from full_pipeline_audit.md
"""

import re
from pathlib import Path

def check_gap_1():
    """GAP 1: Steps 5-9 Next Button Always Enabled"""
    print("\n=== GAP 1: Steps 5-9 isDisabled Logic ===")
    
    steps = [5, 6, 7, 8, 9]
    all_fixed = True
    
    for step in steps:
        file_path = Path(f"app/lib/features/score/flow/step{step}_*.dart")
        matches = list(Path("app/lib/features/score/flow").glob(f"step{step}_*.dart"))
        
        if not matches:
            print(f"❌ Step {step}: File not found")
            all_fixed = False
            continue
            
        content = matches[0].read_text(encoding='utf-8')
        
        # Check if isDisabled is hardcoded to false
        if re.search(r'isDisabled:\s*false', content):
            print(f"❌ Step {step}: Still has 'isDisabled: false' (NOT FIXED)")
            all_fixed = False
        elif re.search(r'isDisabled:\s*!.*isFormValid', content):
            print(f"✅ Step {step}: Has proper isDisabled logic")
        else:
            print(f"⚠️  Step {step}: isDisabled logic unclear")
            all_fixed = False
    
    return all_fixed

def check_gap_2():
    """GAP 2: Loading Spinner During Validation"""
    print("\n=== GAP 2: Validation Loading States ===")
    
    steps = [4, 5, 6, 7, 8, 9]
    any_found = False
    
    for step in steps:
        matches = list(Path("app/lib/features/score/flow").glob(f"step{step}_*.dart"))
        if not matches:
            continue
            
        content = matches[0].read_text(encoding='utf-8')
        
        if re.search(r'_isValidating|Verifying\.\.\.|Cross-checking', content):
            print(f"✅ Step {step}: Has validation loading state")
            any_found = True
        else:
            print(f"❌ Step {step}: No validation loading state")
    
    return any_found

def check_gap_3():
    """GAP 3: Back Navigation Re-Validation"""
    print("\n=== GAP 3: Downstream Step Reset Logic ===")
    
    # Check step status provider
    provider_path = Path("app/lib/state/step_status_provider.dart")
    if not provider_path.exists():
        print("❌ step_status_provider.dart not found")
        return False
    
    content = provider_path.read_text(encoding='utf-8')
    
    if re.search(r'resetDownstream|clearDownstream|invalidateSteps', content):
        print("✅ Downstream reset logic found in provider")
        return True
    else:
        print("❌ No downstream reset logic found")
        return False

def check_gap_4():
    """GAP 4: Bank Statement Merge Logic"""
    print("\n=== GAP 4: Bank Statement Merge ===")
    
    step3_path = Path("app/lib/features/score/flow/step3_bank_screen.dart")
    if not step3_path.exists():
        print("❌ step3_bank_screen.dart not found")
        return False
    
    content = step3_path.read_text(encoding='utf-8')
    
    if re.search(r'merge|append.*transactions|combine.*statements', content, re.IGNORECASE):
        print("✅ Bank statement merge logic found")
        # Check if it's actually implemented or just a comment
        if re.search(r'_transactions\s*=\s*\[\.\.\._transactions,\s*\.\.\.\w+\]', content):
            print("✅ Merge implementation confirmed (transaction append)")
            return True
        else:
            print("⚠️  Merge mentioned but implementation unclear")
            return False
    else:
        print("❌ No merge logic found")
        return False

def check_gap_5():
    """GAP 5: Consecutive Month Check for Utility Bills"""
    print("\n=== GAP 5: Consecutive Month Validation ===")
    
    step4_path = Path("app/lib/features/score/flow/step4_utility_screen.dart")
    if not step4_path.exists():
        print("❌ step4_utility_screen.dart not found")
        return False
    
    content = step4_path.read_text(encoding='utf-8')
    
    # Check for validation function
    if re.search(r'_validateConsecutive|checkConsecutive|validateMonthSequence', content):
        print("✅ Consecutive month validation function found")
        return True
    elif re.search(r'consecutive.*month', content, re.IGNORECASE):
        print("⚠️  'Consecutive month' mentioned in UI but no validation logic")
        return False
    else:
        print("❌ No consecutive month validation")
        return False

def check_gap_6():
    """GAP 6: Backend API Calls in Steps 5-9"""
    print("\n=== GAP 6: Backend API Calls ===")
    
    api_checks = {
        5: ['verifyVehicle', 'getGigHistory'],
        6: ['verifyEshram', 'verifyUdyam', 'verifyPmsym'],
        7: ['verifyInsurance'],
        8: ['getGstFilingHistory', 'verifyItr'],
        9: ['checkLoans']
    }
    
    all_present = True
    
    for step, expected_apis in api_checks.items():
        matches = list(Path("app/lib/features/score/flow").glob(f"step{step}_*.dart"))
        if not matches:
            print(f"❌ Step {step}: File not found")
            all_present = False
            continue
            
        content = matches[0].read_text(encoding='utf-8')
        
        found_apis = []
        missing_apis = []
        
        for api in expected_apis:
            if re.search(rf'api\.{api}\(', content):
                found_apis.append(api)
            else:
                missing_apis.append(api)
        
        if missing_apis:
            print(f"❌ Step {step}: Missing APIs: {', '.join(missing_apis)}")
            all_present = False
        else:
            print(f"✅ Step {step}: All APIs present ({', '.join(found_apis)})")
    
    return all_present

def main():
    print("=" * 60)
    print("GIGCREDIT PIPELINE GAPS VERIFICATION")
    print("=" * 60)
    
    results = {
        "GAP 1 (Steps 5-9 isDisabled)": check_gap_1(),
        "GAP 2 (Validation Loading)": check_gap_2(),
        "GAP 3 (Downstream Reset)": check_gap_3(),
        "GAP 4 (Bank Merge)": check_gap_4(),
        "GAP 5 (Consecutive Months)": check_gap_5(),
        "GAP 6 (Backend APIs)": check_gap_6(),
    }
    
    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)
    
    for gap, status in results.items():
        icon = "✅" if status else "❌"
        status_text = "RESOLVED" if status else "NOT RESOLVED"
        print(f"{icon} {gap}: {status_text}")
    
    resolved_count = sum(results.values())
    total_count = len(results)
    
    print(f"\nTotal: {resolved_count}/{total_count} gaps resolved")
    
    if resolved_count == total_count:
        print("\n🎉 ALL GAPS RESOLVED!")
        return 0
    else:
        print(f"\n⚠️  {total_count - resolved_count} gaps remaining")
        return 1

if __name__ == "__main__":
    exit(main())
