import numpy as np
from PIL import Image
import tflite_runtime.interpreter as tflite
from pathlib import Path
from typing import List, Dict, Tuple
import cv2

from .config import settings

class ModelManager:
    def __init__(self):
        self.interpreter = None
        self.labels = []
        self.input_details = None
        self.output_details = None

    async def initialize(self):
        """Initialize the TFLite model and load labels."""
        try:
            # Load model
            self.interpreter = tflite.Interpreter(
                model_path=str(settings.MODEL_PATH.absolute())
            )
            self.interpreter.allocate_tensors()

            # Get input and output details
            self.input_details = self.interpreter.get_input_details()
            self.output_details = self.interpreter.get_output_details()

            # Load labels
            with open(settings.LABELS_PATH, 'r') as f:
                self.labels = [line.strip() for line in f.readlines()]

        except Exception as e:
            raise RuntimeError(f"Failed to initialize model: {e}")

    def preprocess_image(self, image_path: Path, bbox: Dict[str, float]) -> np.ndarray:
        """Preprocess image for model input."""
        try:
            # Read and crop image
            image = cv2.imread(str(image_path))
            if image is None:
                raise ValueError("Failed to read image")

            height, width = image.shape[:2]
            x1 = int(bbox['left'] * width)
            y1 = int(bbox['top'] * height)
            x2 = int(bbox['right'] * width)
            y2 = int(bbox['bottom'] * height)

            # Ensure coordinates are valid
            x1 = max(0, min(x1, width - 1))
            y1 = max(0, min(y1, height - 1))
            x2 = max(0, min(x2, width))
            y2 = max(0, min(y2, height))

            # Crop and resize
            cropped = image[y1:y2, x1:x2]
            resized = cv2.resize(cropped, (settings.IMAGE_SIZE, settings.IMAGE_SIZE))

            # Convert to RGB
            rgb = cv2.cvtColor(resized, cv2.COLOR_BGR2RGB)

            # Normalize to [-1, 1]
            normalized = (rgb.astype(np.float32) - 127.5) / 127.5

            # Add batch dimension
            return np.expand_dims(normalized, axis=0)

        except Exception as e:
            raise ValueError(f"Failed to preprocess image: {e}")

    def run_inference(self, preprocessed_image: np.ndarray) -> List[Dict[str, float]]:
        """Run model inference on preprocessed image."""
        try:
            # Set input tensor
            self.interpreter.set_tensor(
                self.input_details[0]['index'],
                preprocessed_image
            )

            # Run inference
            self.interpreter.invoke()

            # Get output tensor
            output_data = self.interpreter.get_tensor(
                self.output_details[0]['index']
            )

            # Process results
            results = []
            for i, score in enumerate(output_data[0]):
                if score > settings.CONFIDENCE_THRESHOLD:
                    results.append({
                        'label': self.labels[i],
                        'confidence': float(score)
                    })

            # Sort by confidence
            results.sort(key=lambda x: x['confidence'], reverse=True)
            
            return results[:5]  # Return top 5 predictions

        except Exception as e:
            raise RuntimeError(f"Failed to run inference: {e}")

    async def process_image(self, image_path: Path, bbox: Dict[str, float]) -> List[Dict[str, float]]:
        """Process image and return predictions."""
        try:
            # Preprocess image
            preprocessed = self.preprocess_image(image_path, bbox)
            
            # Run inference
            predictions = self.run_inference(preprocessed)
            
            return predictions

        except Exception as e:
            raise RuntimeError(f"Failed to process image: {e}")

    def __del__(self):
        """Cleanup when the model manager is destroyed."""
        if self.interpreter:
            del self.interpreter 