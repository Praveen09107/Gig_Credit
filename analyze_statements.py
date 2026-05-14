"""Analyze all 3 bank statements to detect bank type & extract transaction structure."""
import pdfplumber
import os

STATEMENTS = [
    r"specification folders_new\Inputs\inputs hardcopies\step -3\Bank Statement -1.pdf",
    r"specification folders_new\Inputs\inputs hardcopies\step -3\Bank Statement - 2.pdf",
    r"specification folders_new\Inputs\inputs hardcopies\step -3\bank statement 3.pdf",
]

BASE = r"C:\Users\PRAVEEN\Desktop\rotatech hackathon\Gig_Credit"

for idx, rel in enumerate(STATEMENTS, 1):
    path = os.path.join(BASE, rel)
    print(f"\n{'='*80}")
    print(f"STATEMENT {idx}: {os.path.basename(path)}")
    print(f"{'='*80}")
    
    if not os.path.exists(path):
        print(f"  FILE NOT FOUND: {path}")
        continue
    
    with pdfplumber.open(path) as pdf:
        print(f"  Pages: {len(pdf.pages)}")
        for pi, page in enumerate(pdf.pages[:3]):  # first 3 pages
            text = page.extract_text() or ""
            print(f"\n  --- Page {pi+1} (first 2000 chars) ---")
            print(text[:2000])
            
            tables = page.extract_tables()
            if tables:
                print(f"\n  --- Tables found: {len(tables)} ---")
                for ti, table in enumerate(tables[:2]):
                    print(f"  Table {ti+1} (first 5 rows):")
                    for row in table[:5]:
                        print(f"    {row}")
