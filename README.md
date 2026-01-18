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

## Planned Architecture Extension

The system is designed to support a modular classification pipeline. Future iterations will introduce additional, domain-specific classifiers to improve accuracy and relevance across different object categories.

The intended flow is to first apply a lightweight general classifier to identify the primary object category (for example: animal, plant, machine, or human). Based on this initial classification, the request is then routed to a specialized model trained for that specific domain, enabling more precise identification while maintaining efficiency and scalability.

This modular approach allows new classifiers to be added incrementally without disrupting the core system, making the platform adaptable to new use cases and datasets over time.
