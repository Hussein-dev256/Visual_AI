from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
import uvicorn

from app.routers import predictions, images
from app.core.config import settings
from app.core.model_manager import ModelManager

app = FastAPI(
    title="Visual AI API",
    description="API for image recognition using MobileNetV3-Small",
    version="1.0.0",
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount static files for image uploads
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# Include routers
app.include_router(predictions.router, prefix="/api/predictions", tags=["predictions"])
app.include_router(images.router, prefix="/api/images", tags=["images"])

# Initialize model on startup
@app.on_event("startup")
async def startup_event():
    try:
        model_manager = ModelManager()
        await model_manager.initialize()
    except Exception as e:
        print(f"Error initializing model: {e}")
        raise HTTPException(status_code=500, detail="Failed to initialize model")

@app.get("/api/health")
async def health_check():
    return JSONResponse({"status": "healthy"})

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
        workers=settings.WORKERS,
    ) 