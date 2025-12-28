from fastapi import FastAPI, UploadFile, File
from fastapi.responses import JSONResponse
from dotenv import load_dotenv
import requests
import os
import traceback
from datetime import datetime, timezone

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
    try:
        image_bytes = await receipt.read()

        response = requests.post(
            "https://api.ocr.space/parse/image",
            files={"file": (receipt.filename, image_bytes, receipt.content_type)},
            data={"apikey": OCR_SPACE_API_KEY, "language": "eng"}
        )

        result = response.json()

        if result.get("IsErroredOnProcessing"):
            return JSONResponse(status_code=400, content={
                "success": False,
                "error": result.get("ErrorMessage"),
                "raw_response": result
            })

        if not result.get("ParsedResults") or not isinstance(result["ParsedResults"], list):
            return JSONResponse(status_code=422, content={
                "success": False,
                "error": "No text detected in image or OCR failed",
                "raw_response": result
            })

        parsed_text = result["ParsedResults"][0].get("ParsedText", "")

        return {
            "success": True,
            "filename": receipt.filename,
            "scanned_at": datetime.now(timezone.utc).isoformat(),
            "ocr_raw_text": parsed_text
        }
    except Exception as e:
        traceback.print_exc()
        return JSONResponse(status_code=500, content={
            "success": False,
            "error": str(e)
        })