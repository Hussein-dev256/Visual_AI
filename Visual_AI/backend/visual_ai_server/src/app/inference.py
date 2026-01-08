import numpy as np
import tflite_runtime.interpreter as tflite
from preprocessor_processor import preprocessImage

class ImageClassifier:
    def __init__(self, model_path: str = "models/models.py", labels_path: str = "models/labels.py"):
        """Initialize TFLite model and labels."""
        self.interpreter = tflite.Interpreter(model_path=model_path)
        self.interpreter.allocate_tensors()
        self.labels = self._load_labels(labels_path)

    def _load_labels(self, path: str) -> list:
        """Load ImageNet labels."""
        with open(path, 'r') as f:
            return [line.strip() for line in f]

    def run_inference(self, image_data: bytes, annotations: List[dict]) -> dict:
        """Run inference on an image."""
        try:
            processed_image = preprocess_image(image_data)
            self.interpreter.set_tensor(self.interpreter.get_input_details()[0]['index'], processed_image)
            self.interpreter.invoke()
            output = self.interpreter.get_tensor(self.interpreter.get_output_details()[0]['index'])
            max_score = float(np.max(output))
            label_index = int(np.argmax(output))
            label = self.labels[label_index]
            return {
                "label": str(label),
                "confidence": float(max_score),
                "annotations": annotations
            }
        except Exception as e:
            raise ValueError(f"Inference failed: {e}")