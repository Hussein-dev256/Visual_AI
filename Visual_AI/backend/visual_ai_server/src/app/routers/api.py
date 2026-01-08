from fastapi import APIRouter, File, UploadFile, HTTPException
from pathlib import Path
from ..core.config import settings
from ..core.schemas import Annotation
import shutil

router = APIRouter(prefix="/api", tags=["api"])

@router.post("/upload")
async def upload_image(file: UploadFile):
    """Upload an image for processing."""
    upload_path = settings.UPLOAD_DIR / file.filename
    try:
        with upload_path.open("wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        return {"filename": file.filename, "path": str(upload_path)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")

@router.post("/annotate")
async def annotate_image(annotation: Annotation):
    """Save annotation for an image."""
    # Placeholder: Save annotation to database (via crud.py)
    return {"status": "Annotation saved", "data": annotation.dict()}