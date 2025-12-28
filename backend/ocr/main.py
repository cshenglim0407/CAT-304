from fastapi import FastAPI, UploadFile, File
from dotenv import load_dotenv
import requests
import os
from datetime import datetime

load_dotenv()

OCR_SPACE_API_KEY = os.getenv("OCR_SPACE_API_KEY")
if not OCR_SPACE_API_KEY:
    raise RuntimeError("OCR_SPACE_API_KEY not found in environment")

app = FastAPI()

@app.get("/")
def read_root():
    return {"status": 200, "message": "Welcome to the OCR Receipt Scanner API"}

@app.get("/health")
def health():
    return {"status": 200, "message": "OK"}

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

    return {
        "success": True,
        "filename": receipt.filename,
        "scanned_at": datetime.now(datetime.timezone.utc).isoformat(),
        "ocr_raw_text": parsed_text
    }