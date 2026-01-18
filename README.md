# Visual AI System

A cross-platform, offline-first image recognition app with a modern UI, built with Flutter (frontend) and FastAPI (backend). Uses MobileNetV3-Small for image classification and C++ for image processing and other performance-critical tasks.

## Features
- Offline image recognition using TFLite.
- User-driven image annotation for items of interest.
- Sleek, modern UI with great UX.
- C++-optimized image processing.
- Backend API for image upload and inference.

## Setup
1. **Frontend**:
   - Navigate to `frontend/visual_ai_app`.
   - Run `flutter pub get`.
   - Build: `flutter build apk --release`.
2. **Backend**:
   - Navigate to `backend/visual_ai_server`.
   - Install: `poetry install` or `pip install -r requirements.txt`.
   - Run: `uvicorn src.app.main:app --reload`.
3. **Docker**:
   - Run: `docker-compose up`.

## Directory Structure
- `frontend/`: Flutter app with TFLite inference and C++ native code.
- `backend/`: FastAPI server with image processing and uploads.
- `uploads/`: Backend storage for user images (in `backend/visual_ai_server`).
