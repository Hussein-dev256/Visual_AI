from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional

class PredictionBase(BaseModel):
    image_path: str
    bbox_left: float = Field(..., ge=0, le=1)
    bbox_top: float = Field(..., ge=0, le=1)
    bbox_right: float = Field(..., ge=0, le=1)
    bbox_bottom: float = Field(..., ge=0, le=1)

class PredictionCreate(PredictionBase):
    pass

class PredictionResponse(PredictionBase):
    id: int
    label: str
    confidence: float
    timestamp: datetime
    is_synced: bool

    class Config:
        from_attributes = True 