from pathlib import Path
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    MODEL_PATH: Path = Path("models/mobilenetv3_small.tflite")
    LABELS_PATH: Path = Path("models/labels.txt")
    UPLOAD_DIR: Path = Path("uploads")
    API_KEY: str = "your_secure_api_key"
    FASTAPI_ENV: str = "development"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

settings = Settings()