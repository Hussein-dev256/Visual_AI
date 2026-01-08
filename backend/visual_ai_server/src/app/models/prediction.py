from sqlalchemy import Column, Integer, String, Float, DateTime, Boolean
from sqlalchemy.sql import func
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()

class Prediction(Base):
    __tablename__ = "predictions"

    id = Column(Integer, primary_key=True, index=True)
    image_path = Column(String, nullable=False)
    label = Column(String, nullable=False)
    confidence = Column(Float, nullable=False)
    bbox_left = Column(Float, nullable=False)
    bbox_top = Column(Float, nullable=False)
    bbox_right = Column(Float, nullable=False)
    bbox_bottom = Column(Float, nullable=False)
    timestamp = Column(DateTime(timezone=True), server_default=func.now())
    is_synced = Column(Boolean, default=False)

    class Config:
        orm_mode = True 