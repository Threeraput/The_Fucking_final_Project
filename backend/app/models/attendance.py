# backend/app/models/attendance.py
import uuid
from sqlalchemy import Column, String, DateTime, ForeignKey, Boolean
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
from app.database import Base

class Attendance(Base):
    __tablename__ = "attendance"

    attendance_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    class_id = Column(UUID(as_uuid=True), ForeignKey("classes.class_id"), nullable=False)
    student_id = Column(UUID(as_uuid=True), ForeignKey("users.user_id"), nullable=False) # สมมติว่านักเรียนเป็น User
    timestamp = Column(DateTime, default=lambda: datetime.now(timezone.utc)) # เวลาที่บันทึกการเข้าเรียน
    status = Column(String(50), nullable=False) # เช่น "present", "absent", "late"
    is_manual_override = Column(Boolean, default=False) # ระบุว่าเป็นการแก้ไขด้วยมือหรือไม่
    recorded_by_user_id = Column(UUID(as_uuid=True), ForeignKey("users.user_id"), nullable=True) # บันทึกโดยใคร (อาจารย์/ผู้ดูแล)

    # Relationships
    class_rel = relationship("Class", back_populates="attendances")
    student_rel = relationship("User", foreign_keys=[student_id], back_populates="attendances")
    recorder_rel = relationship("User", foreign_keys=[recorded_by_user_id], back_populates="recorded_attendances")

    def __repr__(self):
        return f"<Attendance(student_id='{self.student_id}', class_id='{self.class_id}', timestamp='{self.timestamp}', status='{self.status}')>"