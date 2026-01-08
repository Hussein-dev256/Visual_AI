#!/bin/bash

# Set error handling
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up Visual AI Server development environment...${NC}"

# Check Python installation
if command -v python3 &>/dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo -e "${GREEN}Found Python: $PYTHON_VERSION${NC}"
else
    echo -e "${RED}Python not found. Please install Python 3.8 or later.${NC}"
    exit 1
fi

# Create necessary directories
directories=(
    "src/models/mobilenetv3"
    "src/uploads"
    "tests"
    "logs"
)

for dir in "${directories[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo -e "${GREEN}Created directory: $dir${NC}"
    fi
done

# Create and activate virtual environment
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}Creating virtual environment...${NC}"
    python3 -m venv venv
    echo -e "${GREEN}Virtual environment created.${NC}"
fi

# Activate virtual environment
echo -e "${YELLOW}Activating virtual environment...${NC}"
source venv/bin/activate
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Virtual environment activated.${NC}"
else
    echo -e "${RED}Failed to activate virtual environment.${NC}"
    exit 1
fi

# Install dependencies
echo -e "${YELLOW}Installing dependencies...${NC}"
pip install --upgrade pip
pip install -r requirements.txt
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Dependencies installed successfully.${NC}"
else
    echo -e "${RED}Failed to install dependencies.${NC}"
    exit 1
fi

# Install development dependencies
echo -e "${YELLOW}Installing development dependencies...${NC}"
pip install pytest pytest-asyncio pytest-cov black flake8 mypy
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Development dependencies installed successfully.${NC}"
else
    echo -e "${RED}Failed to install development dependencies.${NC}"
    exit 1
fi

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Creating .env file...${NC}"
    cat > .env << EOL
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
EOL
    echo -e "${GREEN}.env file created.${NC}"
fi

# Initialize database
echo -e "${YELLOW}Initializing database...${NC}"
python -c "from app.db.database import init_db; init_db()"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Database initialized successfully.${NC}"
else
    echo -e "${RED}Failed to initialize database.${NC}"
    exit 1
fi

# Set correct permissions
chmod +x scripts/*.sh

echo -e "\n${GREEN}Setup completed successfully!${NC}"
echo -e "\nTo start the development server:"
echo "1. Ensure you're in the src directory"
echo "2. Run: uvicorn main:app --reload --host 0.0.0.0 --port 8000"
echo -e "\nTo run tests:"
echo "pytest" 