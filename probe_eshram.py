"""Quick OCR probe — reads raw text from eShram card to understand its keywords."""
import sys, os
sys.stdout.reconfigure(encoding='utf-8')

from paddleocr import PaddleOCR
ocr = PaddleOCR(use_angle_cls=True, lang='en', show_log=False)

path = r"C:\Users\PRAVEEN\Desktop\rotatech hackathon\Gig_Credit\specification folders_new\Inputs\inputs hardcopies\step-6\eShram Registration\e sharm.jpeg"

result = ocr.ocr(path, cls=True)
lines = []
if result and result[0]:
    for item in result[0]:
        text = item[1][0] if isinstance(item[1], (list,tuple)) else str(item[1])
        lines.append(text.strip())

print(f"=== eShram Card — {len(lines)} lines ===")
for i, l in enumerate(lines):
    print(f"  [{i+1:02d}] {l}")
print("\n=== FULL TEXT ===")
print(" | ".join(lines).lower())
