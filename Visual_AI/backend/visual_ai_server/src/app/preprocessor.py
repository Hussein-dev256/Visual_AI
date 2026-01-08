import cv2
import numpy as np
from ctypes import cdll, c_char_p, c_int

lib = cdll.LoadLibrary("./cpp/libfastprocessor.so")

def preprocess_image(image_data: bytes) -> np.ndarray:
    """Preprocess image using C++."""
    try:
        temp_path = "/tmp/temp.jpg"
        with open(temp_path, "wb") as f:
            f.write(image_data)
        output_path = "/tmp/processed.jpg"
        
        lib.preprocessImage(temp_path.encode('utf-8'), output_path.encode('utf-8'), c_int(224), c_int(224))
        
        image = cv2.imread(temp_path)
        return np.expand_dims(image, axis=0)
    except Exception as e:
        raise ValueError(f"Preprocessing failed: {e}")