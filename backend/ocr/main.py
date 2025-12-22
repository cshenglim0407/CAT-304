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

def extract_total(text: str):
    # Extract all monetary values
    amounts = [float(x) for x in re.findall(r"\d+\.\d{2}", text)]

    if not amounts:
        return None

    # Remove very small values and zeros (item prices, change)
    filtered = [a for a in amounts if a > 1.0]

    if filtered:
        return max(filtered)

    return max(amounts)

def extract_date(text: str):
    match = re.search(r"(\d{2}/\d{2}/\d{4})", text)
    if match:
        return datetime.strptime(match.group(1), "%m/%d/%Y").date().isoformat()
    return None

def extract_merchant(text: str):
    lines = [line.strip() for line in text.splitlines() if line.strip()]

    merchant_keywords = [
        "STORE", "MART", "SHOP", "SUPERMARKET",
        "SDN", "BHD", "ENTERPRISE", "HOLDINGS"
    ]

    blacklist = [
        "TOTAL", "SUBTOTAL", "TAX", "CASH", "CREDIT",
        "ACCOUNT", "ITEM", "QTY", "PRICE", "AMOUNT"
    ]

    candidates = []

    for idx, line in enumerate(lines[:20]):
        upper = line.upper()

        if any(word in upper for word in blacklist):
            continue

        score = 0

        if any(word in upper for word in merchant_keywords):
            score += 5

        if upper.isupper():
            score += 2

        if len(line) >= 10:
            score += 1

        score += max(0, 5 - idx)

        if score > 0:
            candidates.append((score, line))

    if candidates:
        candidates.sort(reverse=True)
        return candidates[0][1]

    return None

@app.get("/")
def health():
    return {"status": "OCR backend running"}

@app.post("/ocr")
async def ocr_receipt(receipt: UploadFile = File(...)):
    image_bytes = await receipt.read()

    response = requests.post(
        "https://api.ocr.space/parse/image",
        files={
            "file": (receipt.filename, image_bytes, receipt.content_type)
        },
        data={
            "apikey": OCR_SPACE_API_KEY,
            "language": "eng"
        }
    )

    result = response.json()

    # 🔴 Handle OCR errors safely
    if result.get("IsErroredOnProcessing"):
        return {
            "success": False,
            "error": result.get("ErrorMessage"),
            "raw_response": result
        }

    # 🟢 Safe extraction
    parsed_text = result["ParsedResults"][0]["ParsedText"]

    merchant = extract_merchant(parsed_text)
    total = extract_total(parsed_text)
    expense_date = extract_date(parsed_text)

    return {
        "success": True,
        "filename": receipt.filename,
        "merchant_name": merchant,
        "total_amount": total,
        "expense_date": expense_date,
        "raw_text": parsed_text
    }