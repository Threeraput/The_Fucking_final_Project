# backend/app/core/config.py
import os
from dotenv import load_dotenv
from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import Optional

load_dotenv() # โหลด environment variables จาก .env

class Settings(BaseSettings):
    # Core Database Setting
    DATABASE_URL: str

    # JWT Authentication Settings
    SECRET_KEY: str
    ALGORITHM: str = "HS256" # ค่าเริ่มต้นถ้าไม่ระบุใน .env
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30 # ค่าเริ่มต้นถ้าไม่ระบุใน .env

    # S3/Cloud Storage Settings (Optional)
    AWS_ACCESS_KEY_ID: Optional[str] = None
    AWS_SECRET_ACCESS_KEY: Optional[str] = None
    AWS_REGION: str = "us-east-1"
    S3_BUCKET_NAME: str = "your-default-bucket-name"

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

settings = Settings()