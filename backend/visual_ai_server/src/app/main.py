from fastapi import FastAPI
from .routers import api
from ..core.config import settings

app = FastAPI(
    title="Visual AI Server",
    description="FastAPI backend for image recognition and annotation",
    version="0.1.0",
)

app.include_router(api.router)

@app.get("/")
async def root():
    return {"message": "Welcome to Visual AI Server"}