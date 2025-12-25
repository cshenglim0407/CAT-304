## OCR Backend

### Endpoint

POST /ocr

### Input

- Multipart form
- Field: receipt (image file)

### Output

- merchant_name
- total_amount
- expense_date
- confidence_score
- scanned_at
- ocr_raw_text

### Notes

- Uses OCR.space
- Confidence is heuristic-based
- Raw text is always preserved
