# backend/app/models/attendance.py
import uuid
from sqlalchemy import Column, DateTime, ForeignKey, Boolean, Numeric
from sqlalchemy import Enum as SAEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
from app.models.attendance_enums import AttendanceStatus

class Attendance(Base):
    __tablename__ = "attendances"

    attendance_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    class_id = Column(UUID(as_uuid=True), ForeignKey("classes.class_id", ondelete="CASCADE"), nullable=False)
    student_id = Column(UUID(as_uuid=True), ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False)

    check_in_time = Column(DateTime(timezone=True), default=func.now())

    # 🔧 ใช้ค่า .value ของ enum ให้ตรงกับ enum type ใน Postgres
    status = Column(
        SAEnum(
            *[e.value for e in AttendanceStatus],   # -> "Present","Late","Absent",...
            name="attendancestatus",                # ให้ตรงกับชื่อ type ใน DB
            native_enum=True,
            create_type=False,                      # ถ้า type มีอยู่แล้วใน DB
            validate_strings=True,
        ),
        default=AttendanceStatus.UNVERIFIED_FACE.value,   # ค่า default เป็น .value
        nullable=False,
    )

    check_in_lat = Column(Numeric(9, 6), nullable=True)
    check_in_lon = Column(Numeric(9, 6), nullable=True)
    is_reverified = Column(Boolean, default=False, nullable=False)

    recorded_by_user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.user_id", ondelete="SET NULL"),
        nullable=True
    )

    # Relationships
    class_rel = relationship("Class", back_populates="attendances")
    student = relationship("User", foreign_keys=[student_id], back_populates="attendances")
    recorder = relationship("User", foreign_keys=[recorded_by_user_id], back_populates="recorded_attendances")

    def __repr__(self):
        return (
            f"<Attendance(student='{self.student_id}', class='{self.class_id}', "
            f"status='{self.status}', time='{self.check_in_time}')>"
        )
