# Visual AI Server

FastAPI backend server for the Visual AI application, providing image recognition capabilities using MobileNetV3-Small.

## Features

- Image upload and management
- Real-time object recognition using TFLite
- Offline-first architecture with SQLite
- RESTful API with OpenAPI documentation
- Efficient image processing and caching
- Cross-platform compatibility

## Prerequisites

- Python 3.8+
- pip package manager
- Virtual environment (recommended)

## Quick Start

### Windows
```powershell
# Clone the repository
git clone <repository-url>
cd visual_ai_server

# Run the setup script
.\scripts\setup_dev.ps1
```

### Linux/macOS
```bash
# Clone the repository
git clone <repository-url>
cd visual_ai_server

# Make the script executable
chmod +x scripts/setup_dev.sh

# Run the setup script
./scripts/setup_dev.sh
```

The setup scripts will:
1. Create necessary directories
2. Set up a virtual environment
3. Install dependencies
4. Create default configuration
5. Initialize the database

## Manual Installation

If you prefer manual setup:

1. Create and activate a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # Linux/Mac
.\venv\Scripts\activate   # Windows
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. For development, install additional tools:
```bash
pip install -r requirements-dev.txt
```

4. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your settings
```

## Development Tools

- **Testing**: pytest, pytest-asyncio, pytest-cov
- **Code Quality**: black, flake8, mypy, isort
- **Documentation**: mkdocs, mkdocs-material
- **Type Checking**: mypy with type stubs

### Code Quality Commands

```bash
# Format code
black .

# Sort imports
isort .

# Lint code
flake8 .

# Type checking
mypy .

# Run tests with coverage
pytest --cov=app tests/
```

## Running the Server

1. Start the development server:
```bash
cd src
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

2. Access the API documentation:
- OpenAPI UI: http://localhost:8000/docs
- ReDoc UI: http://localhost:8000/redoc

## API Endpoints

### Images
- `POST /api/images/upload` - Upload an image
- `GET /api/images/{filename}` - Get an image
- `DELETE /api/images/{filename}` - Delete an image

### Predictions
- `POST /api/predictions/` - Create a prediction
- `GET /api/predictions/` - List predictions
- `GET /api/predictions/{prediction_id}` - Get a prediction

## Project Structure

```
.
├── scripts/
│   ├── setup_dev.ps1
│   └── setup_dev.sh
├── src/
│   ├── app/
│   │   ├── core/
│   │   │   ├── config.py
│   │   │   └── model_manager.py
│   │   ├── db/
│   │   │   └── database.py
│   │   ├── models/
│   │   │   └── prediction.py
│   │   ├── routers/
│   │   │   ├── images.py
│   │   │   └── predictions.py
│   │   └── schemas/
│   │       └── prediction.py
│   ├── models/
│   │   ├── mobilenetv3/
│   │   │   └── mobilenetv3_small.tflite
│   │   └── labels.txt
│   └── main.py
├── tests/
├── requirements.txt
├── requirements-dev.txt
└── README.md
```

## Contributing

1. Create a new branch for your feature
2. Run tests and ensure code quality:
```bash
# Run all quality checks
black . && isort . && flake8 . && mypy . && pytest
```
3. Submit a pull request

## License

MIT License