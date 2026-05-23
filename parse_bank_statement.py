"""
Parse Praveen Kumar's real Axis Bank statement PDF
Extract ALL transactions using balance-change method for credit/debit detection
"""
import pdfplumber
import re
from datetime import datetime
from collections import defaultdict

PDF_PATH = r'specification folders_new\Inputs\inputs hardcopies\step -3\Bank Statement.pdf'

CATEGORY_KEYWORDS = {
    "incomeGig":         ["SWIGGY", "ZOMATO", "OLA", "UBER", "DUNZO", "RAPIDO",
                          "FLIPKART", "AMAZON SELLER", "INDIA POST PAYMENTS",
                          "PRAVEEN DHANAPAL", "PRAVEEN D/INDIA"],
    "incomeSalary":      ["SALARY", "PAYROLL", "WAGES"],
    "govScheme":         ["PMJDY", "DBT", "NREGA", "PM-KISAN", "GOVT"],
    "utilityElectricity":["TANGEDCO", "TNEB", "BESCOM", "ELECTRICITY", "EB BILL", "BBPS"],
    "utilityGas":        ["INDANE", "HP GAS", "BHARAT GAS", "LPG"],
    "utilityMobile":     ["AIRTEL", "JIO", "VODAFONE", "BSNL", "RECHARGE"],
    "utilityInternet":   ["JIOFIBER", "ACT FIBERNET", "BROADBAND", "WIFI"],
    "insurance":         ["LIC", "STAR HEALTH", "ICICI LOMBARD", "HDFC LIFE", "INSURANCE", "PREMIUM"],
    "loanEmi":           ["EMI", "LOAN", "EQUATED", "NACH", "ECS", "AUTO DEBIT"],
    "subscription":      ["NETFLIX", "AMAZON PRIME", "HOTSTAR", "SPOTIFY", "GOOGLE", "BIGTREE", "AMDOX"],
    "food":              ["ZOMATO", "SWIGGY", "BLINKIT", "BIGBASKET", "ZEPTO", "SOLAI PHARMACY"],
    "transfer":          ["UPI", "NEFT", "IMPS", "RTGS", "BHIMCASH"],
    "atm":               ["ATM", "CASH WITHDRAWAL"],
}

def categorize(description: str) -> str:
    desc = description.upper()
    for cat, keywords in CATEGORY_KEYWORDS.items():
        for kw in keywords:
            if kw in desc:
                return cat
    return "other"

def parse_transactions(pdf_path: str):
    """
    Parse Axis Bank statement.
    Format per line: DD-MM-YYYY  [ChqNo]  Particulars  Debit  Credit  Balance  Init.Br
    Debit and Credit are in SEPARATE columns — one will be blank.
    We detect credit vs debit by which column has the amount.
    """
    transactions = []
    
    with pdfplumber.open(pdf_path) as pdf:
        full_text = ""
        for page in pdf.pages:
            full_text += (page.extract_text() or "") + "\n"
    
    lines = full_text.split('\n')
    
    prev_balance = None
    
    for line in lines:
        line = line.strip()
        if not line:
            continue
        
        # Match transaction lines starting with DD-MM-YYYY
        if not re.match(r'^\d{2}-\d{2}-\d{4}', line):
            continue
        
        # Extract all decimal numbers from the line
        numbers = re.findall(r'[\d,]+\.\d{2}', line)
        if len(numbers) < 2:
            continue
        
        try:
            date_str = line[:10]
            date_obj = datetime.strptime(date_str, "%d-%m-%Y")
            
            # Last number is always the running balance
            balance = float(numbers[-1].replace(',', ''))
            
            # Second-to-last is the transaction amount
            amount = float(numbers[-2].replace(',', ''))
            
            # Determine credit or debit by balance change
            if prev_balance is not None:
                diff = balance - prev_balance
                # Allow small floating point tolerance
                if abs(diff - amount) < 1.0:
                    txn_type = "credit"
                elif abs(diff + amount) < 1.0:
                    txn_type = "debit"
                else:
                    # Fallback: if balance went up, credit; else debit
                    txn_type = "credit" if diff > 0 else "debit"
            else:
                # First transaction — use description heuristics
                desc_upper = line.upper()
                txn_type = "credit" if any(kw in desc_upper for kw in [
                    "SHANTHI", "PRABAKARA", "PRAVEEN DHANAPAL", "PRATHISH",
                    "PREETHISH", "SRINATH", "PURUSHOTHAMAN", "BHASKARAN",
                    "ROSHAN", "SRINIVASA", "PRIYANKA", "TASKEEN", "MUNISH",
                    "SIKHANDAR", "MURALIDHARAN", "NPCI BHIM", "J RENUGA",
                    "B SUNDHAR", "R Murugan"
                ]) else "debit"
            
            prev_balance = balance
            
            # Extract description (between date and first amount)
            desc_part = line[10:].strip()
            # Remove all numbers (amounts + balance)
            for num in numbers:
                desc_part = desc_part.replace(num, '').strip()
            # Remove trailing branch code
            desc_part = re.sub(r'\s+\d{3}\s*$', '', desc_part).strip()
            # Clean up extra spaces
            desc_part = re.sub(r'\s+', ' ', desc_part).strip()
            
            if amount > 0 and desc_part:
                transactions.append({
                    "date": date_obj.strftime("%Y-%m-%d"),
                    "amount": amount,
                    "type": txn_type,
                    "description": desc_part,
                    "balance": balance,
                    "category": categorize(desc_part),
                })
        except (ValueError, IndexError):
            continue
    
    return transactions


def compute_monthly_aggregates(transactions):
    monthly_credits = defaultdict(float)
    monthly_debits  = defaultdict(float)
    for txn in transactions:
        month = txn["date"][:7]
        if txn["type"] == "credit":
            monthly_credits[month] += txn["amount"]
        else:
            monthly_debits[month] += txn["amount"]
    return dict(monthly_credits), dict(monthly_debits)


if __name__ == "__main__":
    print("Parsing Praveen Kumar's Axis Bank Statement (balance-change method)...")
    txns = parse_transactions(PDF_PATH)
    
    credits = [t for t in txns if t["type"] == "credit"]
    debits  = [t for t in txns if t["type"] == "debit"]
    print(f"Total: {len(txns)} | Credits: {len(credits)} | Debits: {len(debits)}")
    
    monthly_c, monthly_d = compute_monthly_aggregates(txns)
    
    print("\nMonthly Credits (income):")
    for month in sorted(monthly_c.keys()):
        print(f"  {month}: ₹{monthly_c[month]:,.2f}")
    
    print("\nMonthly Debits (expenses):")
    for month in sorted(monthly_d.keys()):
        print(f"  {month}: ₹{monthly_d[month]:,.2f}")
    
    if monthly_c:
        avg_c = sum(monthly_c.values()) / len(monthly_c)
        avg_d = sum(monthly_d.values()) / len(monthly_d) if monthly_d else 0
        print(f"\nAvg monthly credit: ₹{avg_c:,.2f}")
        print(f"Avg monthly debit:  ₹{avg_d:,.2f}")
        print(f"Net monthly:        ₹{avg_c - avg_d:,.2f}")
    
    print("\nCategory breakdown:")
    from collections import Counter
    cats = Counter(t["category"] for t in txns)
    for cat, count in sorted(cats.items(), key=lambda x: -x[1]):
        total = sum(t["amount"] for t in txns if t["category"] == cat)
        print(f"  {cat}: {count} txns, ₹{total:,.0f}")
    
    print("\nTop 15 transactions by amount:")
    for t in sorted(txns, key=lambda x: -x["amount"])[:15]:
        print(f"  {t['date']} | {t['type']:6} | ₹{t['amount']:8,.2f} | {t['category']:20} | {t['description'][:50]}")

