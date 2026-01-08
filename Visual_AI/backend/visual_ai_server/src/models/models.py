from sqlalchemy import Column, Integer, String, JSON
from ..db.database import Base

class AnnotationModel(Base):
    __tablename__ = "annotations"

    id = Column(Integer, primary_key=True, index=True)
    image_path = Column(String, index=True)
    bounding_boxes = Column(JSON)  # Store as JSON list of [x, y, width, height]
    labels = Column(JSON)  # Store as JSON list of strings