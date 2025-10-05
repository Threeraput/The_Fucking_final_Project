# backend/app/schemas/attendance_schema.py
from pydantic import BaseModel, Field
from typing import Optional, List
from uuid import UUID
from datetime import datetime
from app.models.attendance_enums import AttendanceStatus # นำเข้า Enum

# -----------------
# Request Schemas
# -----------------

class LocationData(BaseModel):
    """ใช้สำหรับรับ Lat/Lon ทั่วไป (เช่น อัปเดตตำแหน่งครู)"""
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)

class AttendanceCheckIn(BaseModel):
    """ใช้เป็น Dependency เพื่อรับ class_id และ Location ในการเช็คอิน"""
    class_id: UUID
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)

class TeacherLocationUpdate(LocationData):
    """ใช้สำหรับรับตำแหน่งล่าสุดของอาจารย์"""
    class_id: UUID # ระบุว่าตำแหน่งนี้เกี่ยวข้องกับคลาสไหน (ถ้ามี)

class StudentLocationLogCreate(LocationData):
    """ใช้สำหรับบันทึก Log ตำแหน่งของนักเรียนระหว่างคาบ"""
    class_id: UUID
    
# -----------------
# Response Schemas
# -----------------
class AttendanceResponse(BaseModel):
    """Response สำหรับการบันทึกการเข้าเรียนสำเร็จ"""
    attendance_id: UUID
    class_id: UUID
    student_id: UUID
    check_in_time: datetime
    status: AttendanceStatus
    is_reverified: bool
    
    class Config:
        from_attributes = True

class TeacherLocationResponse(BaseModel):
    """Response สำหรับข้อมูลตำแหน่งของอาจารย์"""
    teacher_location_id: UUID
    teacher_id: UUID
    class_id: UUID
    latitude: float
    longitude: float
    timestamp: datetime
    
    class Config:
        from_attributes = True