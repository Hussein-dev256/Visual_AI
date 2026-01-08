import unittest
import numpy as np
from src.inference import ImageClassifier
from src.preprocessor import preprocess_image
import os

class TestImageClassifier(unittest.TestCase):
    """Unit tests for ImageClassifier functionality."""

    def setUp(self) -> None:
        """Set up test environment."""
        self.model_path = "models/mobilenetv3_small.tflite"
        self.labels_path = "models/labels.txt"
        self.test_image = "tests/test_image.jpg"
        self.classifier = ImageClassifier(self.model_path, self.labels_path)

    def test_load_labels(self) -> None:
        """Test loading of ImageNet labels."""
        labels = self.classifier._load_labels(self.labels_path)
        self.assertGreater(len(labels), 0, "Labels should not be empty")
        self.assertIsInstance(labels[0], str, "Labels should be strings")

    def test_run_inference(self) -> None:
        """Test inference on a sample image."""
        if not os.path.exists(self.test_image):
            self.skipTest("Test image not found")
        
        with open(self.test_image, "rb") as f:
            image_data = f.read()
        
        processed_image = preprocess_image(image_data)
        result = self.classifier.run_inference(image_data, [])
        
        self.assertIn("label", result, "Result should contain label")
        self.assertIn("confidence", result, "Result should contain confidence")
        self.assertIsInstance(result["confidence"], float, "Confidence should be float")
        self.assertGreaterEqual(result["confidence"], 0.0, "Confidence should be non-negative")

if __name__ == "__main__":
    unittest.main()