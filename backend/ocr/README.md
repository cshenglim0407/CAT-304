## OCR API Contract

### Run locally (Windows)

1. Install Python 3.10+ and pip.
2. From this folder, create/activate a venv:
	- `python -m venv .venv`
	- `.\.venv\Scripts\activate`
3. Set your OCR.Space key (PowerShell): `$env:OCR_SPACE_API_KEY="your_key_here"` (or add a `.env` file next to this README).
4. Install deps: `pip install -r requirements.txt`.
5. Start the server: `uvicorn main:app --reload --host 0.0.0.0 --port 8000`.
6. Health check: `curl http://127.0.0.1:8000/`.
7. OCR example: `curl -F "receipt=@/absolute/path/to/receipt.jpg" http://127.0.0.1:8000/ocr`.

### Deployment (Docker)

1. **Build the image**:
   ```bash
   docker build -t ocr-backend .
   ```
2. **Run locally**:
   ```bash
   docker run -p 8000:8000 -e OCR_SPACE_API_KEY="your_key_here" ocr-backend
   ```
3. **Deploy to Cloud (Render/Railway)**:
   - Push code to Git. Connect repo to provider. Set `OCR_SPACE_API_KEY` env var.

### Endpoint

POST /ocr

### Request

- Content-Type: multipart/form-data
- Field: receipt (image file)

### Response (success)

{
"success": true,
"merchant_name": string | null,
"total_amount": number | null,
"expense_date": string | null,
"confidence_score": number,
"scanned_at": string (ISO),
"ocr_raw_text": string
}

### Notes

- Backend does NOT save data
- Flutter should allow user to edit fields before saving
