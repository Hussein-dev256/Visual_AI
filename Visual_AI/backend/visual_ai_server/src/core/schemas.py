from pydantic import BaseModel
from typing import List, Tuple

class Annotation(BaseModel):
    image_path: str
    bounding_boxes: List[Tuple[float, float, float, float]]  # [x, y, width, height]
    labels: List[str]