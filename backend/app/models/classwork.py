# backend/app/models/classwork.py
import uuid
from sqlalchemy import Column, String, ForeignKey, DateTime, Integer, Boolean, Enum as SAEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import sqlalchemy as sa
from app.database import Base
from app.models.classwork_enums import SubmissionLateness  # ต้องมีค่า On_Time, Late, Not_Submitted

class Classwork(Base):
    __tablename__ = "classwork"

    assignment_id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,                 # หรือจะใช้ server_default=sa.text("uuid_generate_v4()")
    )
    class_id = Column(UUID(as_uuid=True), ForeignKey("classes.class_id", ondelete="CASCADE"), nullable=False)
    teacher_id = Column(UUID(as_uuid=True), ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False)

    title = Column(String(255), nullable=False)
    max_score = Column(Integer, default=100, nullable=False)
    due_date = Column(DateTime(timezone=True), nullable=False)

    # Submission fields
    student_id = Column(UUID(as_uuid=True), ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False)
    content_url = Column(String(512), nullable=True)
    submitted_at = Column(DateTime(timezone=True), nullable=True)

    submission_status = Column(
        SAEnum(
            SubmissionLateness,
            name="submissionlateness",       # 🚩 ชื่อชนิดใน Postgres
            create_type=False,               # 🚩 ใช้ชนิดเดิม ไม่สร้างใหม่
            native_enum=True,
            values_callable=lambda x: [e.value for e in x],  # e.value ต้องเป็น "On_Time"/"Late"/"Not_Submitted"
            validate_strings=True,
        ),
        nullable=False,
        default=SubmissionLateness.NOT_SUBMITTED.value,
        # ถ้าอยากให้ DB ตั้งค่าเองด้วย ให้ปลดคอมเมนต์บรรทัดล่าง (ต้องมั่นใจว่ามี TYPE ใน DB แล้ว)
        # server_default=sa.text("'Not_Submitted'"),
    )

    graded = Column(Boolean, default=False)
    score = Column(Integer, nullable=True)

    # Relationships (ตรวจให้แน่ใจว่าอีกฝั่งมี back_populates ตรงกัน)
    classroom = relationship("Class", back_populates="classwork")
    student_rel = relationship("User", foreign_keys="[Classwork.student_id]", back_populates="class_submissions")
    teacher_rel = relationship("User", foreign_keys="[Classwork.teacher_id]", back_populates="class_assignments")

    __table_args__ = (
        sa.UniqueConstraint('class_id', 'student_id', 'title', name='uq_classwork_submission'),
        sa.Index('ix_classwork_class_student', 'class_id', 'student_id'),
    )
