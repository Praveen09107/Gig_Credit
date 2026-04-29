import PyPDF2
import os

def test_pdf(file_path):
    print(f"\n--- Testing PDF: {os.path.basename(file_path)} ---")
    try:
        with open(file_path, 'rb') as f:
            reader = PyPDF2.PdfReader(f)
            text = ""
            for page in reader.pages:
                text += page.extract_text() + "\n"
                
            clean_text = text.upper().replace(' ', '').replace('\n', '')
            
            # Simulated fuzzy match logic
            keywords = ['STATEMENT', 'ACCOUNTSUMMARY', 'ACCOUNTSTATEMENT']
            banks = ['HDFC', 'ICICI', 'AXIS', 'STATEBANK', 'PUNJABNATIONAL', 'BANKOFBARODA', 'KOTAK']
            
            found_kw = any(kw in clean_text for kw in keywords)
            found_bank = any(b in clean_text for b in banks)
            
            print(f"Extracted length: {len(text)} chars")
            print(f"Found Statement Keyword: {found_kw}")
            print(f"Found Bank Keyword: {found_bank}")
            print("Status: ", "VALID BANK STATEMENT" if (found_kw or found_bank) else "INVALID")
            
    except Exception as e:
        print(f"Error parsing PDF: {e}")

if __name__ == "__main__":
    folder = r"C:\Users\PRAVEEN\Desktop\rotatech hackathon\Gig_Credit\specification folders_new\Inputs\inputs hardcopies\step -3"
    files = ["Bank Statement - 2.pdf", "Bank Statement - 3.pdf", "Bank Statement -1.pdf"]
    for f in files:
        test_pdf(os.path.join(folder, f))
