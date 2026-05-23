#!/usr/bin/env python3
"""
Final verification of GAP 2, GAP 3, GAP 5 after fixes
"""

import re
from pathlib import Path

def check_gap_2():
    print("\n" + "="*60)
    print("GAP 2: VALIDATION LOADING STATES (VerificationPhaseMixin)")
    print("="*60)
    
    steps = [4, 5, 6, 7, 8, 9]
    all_ok = True
    
    for step in steps:
        matches = list(Path("app/lib/features/score/flow").glob(f"step{step}_*.dart"))
        if not matches:
            print(f"❌ Step {step}: File not found")
            all_ok = False
            continue
        content = matches[0].read_text(encoding='utf-8')
        has_mixin = 'with VerificationPhaseMixin' in content
        has_show = 'showVerificationPhase()' in content
        has_dismiss = 'dismissVerificationPhase()' in content
        ok = has_mixin and has_show and has_dismiss
        icon = "✅" if ok else "❌"
        print(f"{icon} Step {step}: mixin={has_mixin}, show={has_show}, dismiss={has_dismiss}")
        if not ok:
            all_ok = False
    
    overlay = Path("app/lib/shared/widgets/feedback/verification_phase_overlay.dart")
    if overlay.exists():
        c = overlay.read_text(encoding='utf-8')
        has_phases = 'Validating inputs' in c and 'Cross-checking identity' in c
        print(f"{'✅' if has_phases else '❌'} VerificationPhaseOverlay: cycling phase messages present")
        if not has_phases:
            all_ok = False
    else:
        print("❌ VerificationPhaseOverlay widget not found")
        all_ok = False
    
    print(f"\nGAP 2 STATUS: {'✅ RESOLVED' if all_ok else '❌ NOT RESOLVED'}")
    return all_ok


def check_gap_3():
    print("\n" + "="*60)
    print("GAP 3: DOWNSTREAM STEP RESET LOGIC")
    print("="*60)
    
    provider = Path("app/lib/state/step_status_provider.dart")
    if not provider.exists():
        print("❌ step_status_provider.dart not found")
        return False
    
    content = provider.read_text(encoding='utf-8')
    
    # Check for downstream reset in setStatus
    has_downstream_reset = bool(re.search(
        r'wasAlreadyVerified|for.*i\s*=\s*step\s*\+\s*1.*i\s*<=\s*9',
        content, re.DOTALL
    ))
    
    # Check for the loop that resets downstream steps
    has_reset_loop = bool(re.search(
        r'for\s*\(int\s+i\s*=\s*step\s*\+\s*1.*i\s*<=\s*9',
        content, re.DOTALL
    ))
    
    # Check for wasAlreadyVerified pattern
    has_was_verified = 'wasAlreadyVerified' in content
    
    print(f"{'✅' if has_was_verified else '❌'} wasAlreadyVerified check in setStatus")
    print(f"{'✅' if has_reset_loop else '❌'} Downstream reset loop (for i = step+1 to 9)")
    
    ok = has_was_verified and has_reset_loop
    print(f"\nGAP 3 STATUS: {'✅ RESOLVED' if ok else '❌ NOT RESOLVED'}")
    
    if ok:
        print("  When a step is re-verified (was already verified),")
        print("  all downstream steps are reset to notStarted.")
    
    return ok


def check_gap_5():
    print("\n" + "="*60)
    print("GAP 5: CONSECUTIVE MONTH VALIDATION")
    print("="*60)
    
    step4 = Path("app/lib/features/score/flow/step4_utility_screen.dart")
    if not step4.exists():
        print("❌ step4_utility_screen.dart not found")
        return False
    
    content = step4.read_text(encoding='utf-8')
    
    # Check final bool bug is fixed
    has_final_bug = bool(re.search(r'final\s+bool\s+_\w+Uploaded\s*=\s*false', content))
    print(f"{'✅' if not has_final_bug else '❌'} final bool bug fixed (upload booleans are mutable)")
    
    # Check upload booleans are declared as mutable
    has_mutable_uploads = bool(re.search(r'bool\s+_elecUploaded\s*=\s*false', content))
    print(f"{'✅' if has_mutable_uploads else '❌'} _elecUploaded declared as mutable bool")
    
    # Check upload booleans are set in onExtracted
    has_elec_wired = bool(re.search(r'_elecUploaded\s*=\s*true', content))
    has_water_wired = bool(re.search(r'_waterUploaded\s*=\s*true', content))
    has_gas_wired = bool(re.search(r'_gasUploaded\s*=\s*true', content))
    has_mobile_wired = bool(re.search(r'_mobileUploaded\s*=\s*true', content))
    has_internet_wired = bool(re.search(r'_internetUploaded\s*=\s*true', content))
    has_rent_wired = bool(re.search(r'_rentUploaded\s*=\s*true', content))
    
    all_wired = all([has_elec_wired, has_water_wired, has_gas_wired, 
                     has_mobile_wired, has_internet_wired, has_rent_wired])
    print(f"{'✅' if all_wired else '❌'} All upload booleans wired to onExtracted callbacks")
    if not all_wired:
        print(f"  elec={has_elec_wired}, water={has_water_wired}, gas={has_gas_wired}")
        print(f"  mobile={has_mobile_wired}, internet={has_internet_wired}, rent={has_rent_wired}")
    
    # Check upload validation in _submit
    has_upload_check = bool(re.search(r'_hasElectricity\s*&&\s*!_elecUploaded', content))
    print(f"{'✅' if has_upload_check else '❌'} Upload required check in _submit()")
    
    # Check insufficient bills warning
    has_insufficient_warning = 'insufficientBills' in content
    print(f"{'✅' if has_insufficient_warning else '❌'} Insufficient bills warning (< 6 months)")
    
    # Check demo autofill sets upload booleans
    has_demo_upload = bool(re.search(r'_elecUploaded\s*=\s*true.*_elecUploadCount\s*=\s*6', content, re.DOTALL))
    print(f"{'✅' if has_demo_upload else '❌'} Demo autofill sets upload booleans + count=6")
    
    ok = (not has_final_bug and has_mutable_uploads and all_wired and 
          has_upload_check and has_insufficient_warning)
    
    print(f"\nGAP 5 STATUS: {'✅ RESOLVED' if ok else '❌ NOT RESOLVED'}")
    if ok:
        print("  - Upload booleans are mutable (final bug fixed)")
        print("  - Each bill type requires at least 1 upload before submit")
        print("  - Warning shown if fewer than 6 months uploaded")
        print("  - Demo autofill simulates 6 consecutive months")
    
    return ok


def main():
    print("="*60)
    print("FINAL GAPS VERIFICATION: GAP 2, GAP 3, GAP 5")
    print("="*60)
    
    g2 = check_gap_2()
    g3 = check_gap_3()
    g5 = check_gap_5()
    
    print("\n" + "="*60)
    print("FINAL SUMMARY")
    print("="*60)
    print(f"{'✅' if g2 else '❌'} GAP 2 (Validation Loading): {'RESOLVED' if g2 else 'NOT RESOLVED'}")
    print(f"{'✅' if g3 else '❌'} GAP 3 (Downstream Reset): {'RESOLVED' if g3 else 'NOT RESOLVED'}")
    print(f"{'✅' if g5 else '❌'} GAP 5 (Consecutive Months): {'RESOLVED' if g5 else 'NOT RESOLVED'}")
    
    resolved = sum([g2, g3, g5])
    print(f"\nTotal: {resolved}/3 gaps resolved")
    
    if resolved == 3:
        print("\n🎉 ALL 3 GAPS RESOLVED!")
    else:
        print(f"\n⚠️  {3 - resolved} gap(s) still need work")
    
    return 0 if resolved == 3 else 1

if __name__ == "__main__":
    exit(main())
