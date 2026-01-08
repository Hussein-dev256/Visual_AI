from pydantic_settings import BaseSettings
from pathlib import Path

class Settings(BaseSettings):
    # API Settings
    API_V1_STR: str = "/api"
    PROJECT_NAME: str = "Visual AI"
    DEBUG: bool = True
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    WORKERS: int = 1

    # Model Settings
    MODEL_PATH: Path = Path("models/mobilenetv3/mobilenetv3_small.tflite")
    LABELS_PATH: Path = Path("models/labels.txt")
    IMAGE_SIZE: int = 224
    CONFIDENCE_THRESHOLD: float = 0.1

    # Database Settings
    DATABASE_URL: str = "sqlite:///./visual_ai.db"
    
    # File Storage Settings
    UPLOAD_DIR: Path = Path("uploads")
    MAX_UPLOAD_SIZE: int = 10 * 1024 * 1024  # 10MB
    ALLOWED_EXTENSIONS: set = {"jpg", "jpeg", "png"}

    # Cache Settings
    CACHE_TTL: int = 3600  # 1 hour
    MAX_CACHE_SIZE: int = 1000

    class Config:
        case_sensitive = True
        env_file = ".env"

settings = Settings()

# Ensure required directories exist
settings.UPLOAD_DIR.mkdir(parents=True, exist_ok=True) 