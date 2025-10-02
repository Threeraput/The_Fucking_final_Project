# backend/app/schemas/class_schema.py
from pydantic import BaseModel, Field
from typing import List, Optional
from uuid import UUID
from datetime import datetime

# Import User Schema (ถ้ามี)
from app.schemas.user_schema import UserResponse # (สมมติว่าคุณมี UserResponse)

# -----------------
# Request Schemas
# -----------------
class ClassroomCreate(BaseModel):
    name: str = Field(..., max_length=100)

class ClassroomJoin(BaseModel):
    code: str = Field(..., max_length=10, description="The unique code to join the classroom")

# -----------------
# Response Schemas
# -----------------
class ClassroomResponseBase(BaseModel):
    class_id: UUID
    name: str
    code: str
    teacher_id: UUID
    created_at: datetime
    
    class Config:
        from_attributes = True

# Response สำหรับการแสดงข้อมูลห้องเรียนพร้อมรายละเอียดครู/นักเรียน
class ClassroomResponse(ClassroomResponseBase):
    # ปรับปรุง: ใช้ชื่อ role ใน UserResponse
    teacher: Optional[UserResponse] 
    students: List[UserResponse] = []
    
    # update class
class ClassroomUpdate(BaseModel):
    # 1. จัดเรียง Field ที่ไม่มีการกำหนดค่าเริ่มต้นที่ซับซ้อนไว้ด้านบน
    name: Optional[str] = Field(None, max_length=100)
    description: Optional[str] = None 
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None