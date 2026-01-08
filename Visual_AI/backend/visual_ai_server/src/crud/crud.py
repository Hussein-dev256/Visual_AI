from sqlalchemy.orm import Session
from ..models.models import AnnotationModel
from ..core.schemas import Annotation

def create_annotation(db: Session, annotation: Annotation):
    """Create a new annotation in the database."""
    db_annotation = AnnotationModel(
        image_path=annotation.image_path,
        bounding_boxes=annotation.bounding_boxes,
        labels=annotation.labels,
    )
    db.add(db_annotation)
    db.commit()
    db.refresh(db_annotation)
    return db_annotation