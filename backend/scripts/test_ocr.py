from paddleocr import PaddleOCR
import os

ocr = PaddleOCR(use_angle_cls=True, lang='en')

def test_image(img_path):
    print(f"\n--- Testing: {os.path.basename(img_path)} ---")
    result = ocr.ocr(img_path, cls=True)
    if not result or not result[0]:
        print("No text found.")
        return
        
    for line in result[0]:
        text = line[1][0]
        confidence = line[1][1]
        print(f"[{confidence:.2f}] {text}")

if __name__ == "__main__":
    folder = r"C:\Users\PRAVEEN\Desktop\rotatech hackathon\Gig_Credit\specification folders_new\Inputs\inputs hardcopies\step -2"
    
    files = [
        "adar front card.jpeg",
        "adar card bacck side .jpeg",
        "pan card front .jpeg"
    ]
    
    for f in files:
        test_image(os.path.join(folder, f))
