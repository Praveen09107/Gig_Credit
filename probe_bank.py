"""Probe: print lines 25-120 from each statement to understand transaction format."""
import sys, fitz, os
sys.stdout.reconfigure(encoding='utf-8')

BASE = r"C:\Users\PRAVEEN\Desktop\rotatech hackathon\Gig_Credit\specification folders_new\Inputs\inputs hardcopies\step -3"

files = [
    ("Bank Statement - 2.pdf", "Type-1"),
    ("Bank Statement -1.pdf",  "Type-2"),
    ("Bank Statement - 3.pdf", "Type-3"),
]

for fname, label in files:
    path = os.path.join(BASE, fname)
    doc = fitz.open(path)
    print(f"\n{'='*70}")
    print(f"  [{label}] {fname}")
    print(f"{'='*70}")

    # Dump page 1 and page 2 raw text
    for pg_idx in range(min(2, len(doc))):
        page = doc[pg_idx]
        raw = page.get_text("text")
        lines = [l.strip() for l in raw.splitlines() if l.strip()]
        print(f"\n  -- Page {pg_idx+1} ({len(lines)} lines) --")
        for i, l in enumerate(lines[:80]):
            print(f"  [{i+1:03d}] {repr(l)}")

    # Also try "blocks" mode for columnar layout
    print(f"\n  -- Page 1 BLOCKS mode (shows column groupings) --")
    page1 = doc[0]
    blocks = page1.get_text("blocks")  # returns list of (x0,y0,x1,y1,text,block_no,block_type)
    for i, b in enumerate(blocks[:20]):
        text_snippet = repr(b[4][:120].replace('\n', ' | '))
        print(f"  Block {i:02d} y={b[1]:.0f}: {text_snippet}")

    doc.close()
    print()
