from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List
from pathlib import Path

from ..core.model_manager import ModelManager
from ..db.database import get_db
from ..models.prediction import Prediction
from ..schemas.prediction import PredictionCreate, PredictionResponse

router = APIRouter()
model_manager = ModelManager()

@router.post("/", response_model=List[PredictionResponse])
async def create_prediction(
    prediction: PredictionCreate,
    db: Session = Depends(get_db),
):
    """Create a new prediction."""
    try:
        # Verify image exists
        image_path = Path(prediction.image_path)
        if not image_path.exists():
            raise HTTPException(status_code=404, detail="Image not found")

        # Process image and get predictions
        predictions = await model_manager.process_image(
            image_path=image_path,
            bbox={
                'left': prediction.bbox_left,
                'top': prediction.bbox_top,
                'right': prediction.bbox_right,
                'bottom': prediction.bbox_bottom,
            }
        )

        if not predictions:
            raise HTTPException(
                status_code=400,
                detail="No predictions found for the given image"
            )

        # Save prediction to database
        db_prediction = Prediction(
            image_path=str(image_path),
            label=predictions[0]['label'],
            confidence=predictions[0]['confidence'],
            bbox_left=prediction.bbox_left,
            bbox_top=prediction.bbox_top,
            bbox_right=prediction.bbox_right,
            bbox_bottom=prediction.bbox_bottom,
            is_synced=True
        )
        db.add(db_prediction)
        db.commit()
        db.refresh(db_prediction)

        return predictions

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/", response_model=List[PredictionResponse])
async def get_predictions(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
):
    """Get all predictions."""
    predictions = db.query(Prediction).offset(skip).limit(limit).all()
    return predictions

@router.get("/{prediction_id}", response_model=PredictionResponse)
async def get_prediction(
    prediction_id: int,
    db: Session = Depends(get_db),
):
    """Get a specific prediction."""
    prediction = db.query(Prediction).filter(Prediction.id == prediction_id).first()
    if prediction is None:
        raise HTTPException(status_code=404, detail="Prediction not found")
    return prediction 