# backend/app/schemas/session_schema.py
from pydantic import BaseModel, Field
from typing import Optional, List
from uuid import UUID
from datetime import datetime

class LocationData(BaseModel):
    """Base model for Lat/Lon"""
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)

class SessionOpenRequest(LocationData):
    """ใช้สำหรับ Teacher เปิด Session"""
    class_id: UUID
    # Optional: กำหนดเวลาสิ้นสุดเองได้ (ถ้าไม่กำหนดจะใช้ Default 15 นาที)
    end_time: Optional[datetime] = None 

class SessionResponse(BaseModel):
    """Response สำหรับ Session ที่ถูกสร้าง"""
    session_id: UUID
    class_id: UUID
    teacher_id: UUID
    start_time: datetime
    end_time: datetime
    anchor_lat: float
    anchor_lon: float
    
    class Config:
        from_attributes = True