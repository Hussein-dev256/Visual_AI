from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import FileResponse
from pathlib import Path
import aiofiles
import uuid
import imghdr
from typing import Optional

from ..core.config import settings

router = APIRouter()

def validate_image(file: UploadFile) -> bool:
    """Validate image file type and size."""
    # Check file size
    if file.size > settings.MAX_UPLOAD_SIZE:
        raise HTTPException(
            status_code=400,
            detail=f"File size too large. Maximum size is {settings.MAX_UPLOAD_SIZE/1024/1024}MB"
        )
    
    # Check file extension
    ext = file.filename.split('.')[-1].lower()
    if ext not in settings.ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"File type not allowed. Allowed types: {settings.ALLOWED_EXTENSIONS}"
        )
    
    return True

async def save_upload_file(file: UploadFile) -> Path:
    """Save uploaded file to disk."""
    try:
        # Create unique filename
        ext = file.filename.split('.')[-1].lower()
        filename = f"{uuid.uuid4()}.{ext}"
        file_path = settings.UPLOAD_DIR / filename

        # Save file
        async with aiofiles.open(file_path, 'wb') as f:
            content = await file.read()
            await f.write(content)

        # Verify it's a valid image
        if not imghdr.what(file_path):
            file_path.unlink()  # Delete invalid file
            raise HTTPException(
                status_code=400,
                detail="Invalid image file"
            )

        return file_path

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to save file: {str(e)}"
        )

@router.post("/upload")
async def upload_image(file: UploadFile = File(...)):
    """Upload an image file."""
    try:
        validate_image(file)
        file_path = await save_upload_file(file)
        
        return {
            "status": "success",
            "message": "File uploaded successfully",
            "path": str(file_path)
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to process upload: {str(e)}"
        )

@router.get("/{filename}")
async def get_image(filename: str):
    """Get an image by filename."""
    file_path = settings.UPLOAD_DIR / filename
    
    if not file_path.exists():
        raise HTTPException(
            status_code=404,
            detail="Image not found"
        )
    
    return FileResponse(file_path)

@router.delete("/{filename}")
async def delete_image(filename: str):
    """Delete an image by filename."""
    file_path = settings.UPLOAD_DIR / filename
    
    if not file_path.exists():
        raise HTTPException(
            status_code=404,
            detail="Image not found"
        )
    
    try:
        file_path.unlink()
        return {"status": "success", "message": "File deleted successfully"}
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to delete file: {str(e)}"
        ) 