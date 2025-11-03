# backend/app/schemas/classwork_schema.py
from uuid import UUID
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict, AwareDatetime
from app.models.classwork_enums import SubmissionLateness  # "On_Time", "Late", "Not_Submitted"

# -----------------
# Request Schemas
# -----------------
class ClassworkCreate(BaseModel):
    """Input สำหรับ Teacher สร้างใบงาน"""
    title: str = Field(..., max_length=255)
    max_score: int = Field(100, ge=1, le=100)   # เพดาน 100 ตามดีฟอลต์ใน DB
    due_date: AwareDatetime
    class_id: UUID

class SubmissionUploadMetadata(BaseModel):
    """Metadata ที่นักเรียนส่งมาพร้อมไฟล์งาน"""
    assignment_id: UUID

class GradeSubmission(BaseModel):
    """Input สำหรับ Teacher ให้คะแนน"""
    score: int = Field(..., ge=0)  # การเช็ค <= max_score ทำที่ service layer (เทียบกับโจทย์จริง)

# -----------------
# Response Schemas
# -----------------
class _ClassworkBase(BaseModel):
    """ฟิลด์ที่ทั้ง Assignment/Submission ใช้ร่วมกัน"""
    assignment_id: UUID
    class_id: UUID
    teacher_id: UUID
    title: str
    max_score: int
    due_date: AwareDatetime

    # เปิด ORM mode + ให้ enum serialize เป็นค่า value ("On_Time")
    model_config = ConfigDict(use_enum_values=True, from_attributes=True)

class ClassworkResponse(_ClassworkBase):
    """Output สำหรับ Assignment (โจทย์)"""
    pass

class SubmissionResponse(_ClassworkBase):
    """Output สำหรับ Submission (งานที่ส่ง)"""
    student_id: UUID
    content_url: Optional[str] = None
    submitted_at: Optional[AwareDatetime] = None
    submission_status: SubmissionLateness
    graded: bool
    score: Optional[int] = None
