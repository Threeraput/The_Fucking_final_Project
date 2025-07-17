# backend/app/database.py
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from app.core.config import settings

# ตรวจสอบว่า DATABASE_URL มีค่าหรือไม่
if not settings.DATABASE_URL:
    raise ValueError("DATABASE_URL is not set in environment variables.")

# เชื่อมต่อกับ PostgreSQL
SQLALCHEMY_DATABASE_URL = settings.DATABASE_URL

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

# Dependency สำหรับการรับ Database Session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()