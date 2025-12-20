from fastapi import FastAPI, UploadFile, File
from dotenv import load_dotenv
import requests
import os

load_dotenv()

OCR_SPACE_API_KEY = os.getenv("OCR_SPACE_API_KEY")

app = FastAPI()

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

    return {
        "success": True,
        "filename": receipt.filename,
        "parsed_text": parsed_text
    }