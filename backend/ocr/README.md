## OCR API Contract

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
