# Visual AI Server

FastAPI backend for the Visual AI image recognition system, providing endpoints for image upload, annotation, and inference using MobileNetV3-Small.

## Setup
1. Install dependencies: `poetry install` or `pip install -r requirements.txt`.
2. Set environment variables in `.env`.
3. Run server: `uvicorn src.app.main:app --reload`.

## Endpoints
- `POST /upload`: Upload and process images.
- `POST /annotate`: Save annotations for uploaded images.
- `GET /predict`: Run inference on uploaded images.

## Directory Structure
- `src/`: API logic and preprocessing.
- `uploads/`: User-uploaded images.
- `models/`: TFLite model and labels.
- `tests/`: Unit tests.