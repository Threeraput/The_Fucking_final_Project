from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from uuid import UUID


class AttendanceReportBase(BaseModel):
    class_id: UUID
    student_id: UUID
    total_sessions: int
    attended_sessions: int
    absent_sessions: int
    reverified_sessions: int
    attendance_rate: float
    generated_at: datetime


class AttendanceReportCreate(BaseModel):
    class_id: UUID
    student_id: UUID


class AttendanceReportResponse(AttendanceReportBase):
    report_id: UUID

    class Config:
        orm_mode = True
        

class AttendanceReportDetailResponse(BaseModel):
    session_id: UUID
    check_in_time: Optional[datetime]
    status: str
    is_reverified: bool

    class Config:
        orm_mode = True


class AttendanceReportResponse(BaseModel):
    report_id: UUID
    class_id: UUID
    student_id: UUID
    total_sessions: int
    attended_sessions: int
    late_sessions: int
    absent_sessions: int
    left_early_sessions: int
    reverified_sessions: int
    attendance_rate: float
    generated_at: datetime
    details: List[AttendanceReportDetailResponse] = []

    class Config:
        orm_mode = True
