# Visual AI Server Development Environment Setup Script for Windows
Write-Host "Setting up Visual AI Server development environment..." -ForegroundColor Green

# Check Python installation
try {
    $pythonVersion = python --version
    Write-Host "Found Python: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "Python not found. Please install Python 3.8 or later." -ForegroundColor Red
    exit 1
}

# Create necessary directories
$directories = @(
    "src/models/mobilenetv3",
    "src/uploads",
    "tests",
    "logs"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force
        Write-Host "Created directory: $dir" -ForegroundColor Green
    }
}

# Create and activate virtual environment
if (-not (Test-Path "venv")) {
    Write-Host "Creating virtual environment..." -ForegroundColor Yellow
    python -m venv venv
    Write-Host "Virtual environment created." -ForegroundColor Green
}

# Activate virtual environment
Write-Host "Activating virtual environment..." -ForegroundColor Yellow
.\venv\Scripts\Activate
if ($?) {
    Write-Host "Virtual environment activated." -ForegroundColor Green
} else {
    Write-Host "Failed to activate virtual environment." -ForegroundColor Red
    exit 1
}

# Install dependencies
Write-Host "Installing dependencies..." -ForegroundColor Yellow
pip install --upgrade pip
pip install -r requirements.txt
if ($?) {
    Write-Host "Dependencies installed successfully." -ForegroundColor Green
} else {
    Write-Host "Failed to install dependencies." -ForegroundColor Red
    exit 1
}

# Install development dependencies
Write-Host "Installing development dependencies..." -ForegroundColor Yellow
pip install pytest pytest-asyncio pytest-cov black flake8 mypy
if ($?) {
    Write-Host "Development dependencies installed successfully." -ForegroundColor Green
} else {
    Write-Host "Failed to install development dependencies." -ForegroundColor Red
    exit 1
}

# Create .env file if it doesn't exist
if (-not (Test-Path ".env")) {
    Write-Host "Creating .env file..." -ForegroundColor Yellow
    @"
# API Settings
DEBUG=True
HOST=0.0.0.0
PORT=8000
WORKERS=1

# Database Settings
DATABASE_URL=sqlite:///./visual_ai.db

# Model Settings
MODEL_PATH=models/mobilenetv3/mobilenetv3_small.tflite
LABELS_PATH=models/labels.txt
CONFIDENCE_THRESHOLD=0.1

# File Storage Settings
MAX_UPLOAD_SIZE=10485760
"@ | Out-File -FilePath ".env" -Encoding UTF8
    Write-Host ".env file created." -ForegroundColor Green
}

# Initialize database
Write-Host "Initializing database..." -ForegroundColor Yellow
python -c "from app.db.database import init_db; init_db()"
if ($?) {
    Write-Host "Database initialized successfully." -ForegroundColor Green
} else {
    Write-Host "Failed to initialize database." -ForegroundColor Red
    exit 1
}

Write-Host "`nSetup completed successfully!" -ForegroundColor Green
Write-Host "`nTo start the development server:"
Write-Host "1. Ensure you're in the src directory"
Write-Host "2. Run: uvicorn main:app --reload --host 0.0.0.0 --port 8000"
Write-Host "`nTo run tests:"
Write-Host "pytest" 