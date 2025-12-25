from fastapi import FastAPI, UploadFile, File
from dotenv import load_dotenv
import requests
import os
import re
from datetime import datetime

load_dotenv()

OCR_SPACE_API_KEY = os.getenv("OCR_SPACE_API_KEY")
if not OCR_SPACE_API_KEY:
    raise RuntimeError("OCR_SPACE_API_KEY not found in environment")

app = FastAPI()

MERCHANT_KEYWORDS = [
    "LIDL", "WALMART", "WALL-MART", "TESCO", "ALDI",
    "CARREFOUR", "AEON", "GIANT", "LOTUS",
    "MYDIN", "7-ELEVEN"
]

def extract_merchant(text: str):
    lines = [l.strip() for l in text.splitlines() if l.strip()]

    # 1️⃣ ABSOLUTE PRIORITY: known merchant keywords
    # Brand name always beats heuristics
    for line in lines:
        upper = line.upper()
        for keyword in MERCHANT_KEYWORDS:
            if keyword in upper:
                return line

    # 2️⃣ FALLBACK: heuristic scoring (brand not recognised)
    best_line = None
    best_score = -999

    for idx, line in enumerate(lines):
        score = 0
        lower = line.lower()

        # Uppercase store-style names
        if line.isupper():
            score += 2

        # Typical merchant length
        if 2 <= len(line.split()) <= 5:
            score += 1

        # Strong product penalties
        if re.search(r"\bkg\b|\bx\b|eur|€|\d+[.,]\d{2}", lower):
            score -= 6

        # 🚫 Reject dense product blocks
        window = lines[max(0, idx-4):min(len(lines), idx+5)]
        product_neighbors = sum(
            1 for w in window
            if re.search(r"\bkg\b|\bx\b|\d+[.,]\d{2}", w.lower())
        )
        if product_neighbors >= 3:
            score -= 20

        if score > best_score:
            best_score = score
            best_line = line

    return best_line

def extract_total(text: str):
    lines = [l.strip() for l in text.splitlines() if l.strip()]

    for i, line in enumerate(lines):
        if "TOTAL" in line.upper():
            candidates = []

            # Look 4 lines ABOVE and BELOW
            for j in range(max(0, i-4), min(len(lines), i+5)):
                if "%" in lines[j]:
                    continue

                nums = re.findall(r"\d+[.,]\d{2}", lines[j])
                for n in nums:
                    candidates.append(float(n.replace(",", ".")))

            if candidates:
                return max(candidates)

    return None

def extract_date(text: str):
    patterns = [
        (r"\b\d{2}/\d{2}/\d{4}\b", "%m/%d/%Y"),
        (r"\b\d{2}\.\d{2}\.\d{2}\b", "%d.%m.%y"),
        (r"\b\d{2}\.\d{2}\.\d{4}\b", "%d.%m.%Y"),
    ]
    for pattern, fmt in patterns:
        match = re.search(pattern, text)
        if match:
            try:
                return datetime.strptime(match.group(), fmt).date().isoformat()
            except ValueError:
                pass
    return None

def compute_confidence(merchant, total, date):
    score = 0
    if merchant:
        score += 0.3
    if total:
        score += 0.4
    if date:
        score += 0.3
    return round(score, 2)

@app.get("/")
def health():
    return {"status": "OCR backend running"}

@app.post("/ocr")
async def ocr_receipt(receipt: UploadFile = File(...)):
    image_bytes = await receipt.read()

    response = requests.post(
        "https://api.ocr.space/parse/image",
        files={"file": (receipt.filename, image_bytes, receipt.content_type)},
        data={"apikey": OCR_SPACE_API_KEY, "language": "eng"}
    )

    result = response.json()

    if result.get("IsErroredOnProcessing"):
        return {
            "success": False,
            "error": result.get("ErrorMessage"),
            "raw_response": result
        }

    parsed_text = result["ParsedResults"][0]["ParsedText"]

    merchant = extract_merchant(parsed_text)
    total = extract_total(parsed_text)
    expense_date = extract_date(parsed_text)
    confidence = compute_confidence(merchant, total, expense_date)
    confidence = min(0.95, confidence)

    return {
        "success": True,
        "filename": receipt.filename,
        "merchant_name": merchant,
        "total_amount": total,
        "expense_date": expense_date,
        "confidence_score": confidence,
        "scanned_at": datetime.utcnow().isoformat(),
        "ocr_raw_text": parsed_text
    }