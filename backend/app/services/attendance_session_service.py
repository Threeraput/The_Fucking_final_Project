# backend/app/services/attendance_session_service.py
import uuid
import logging
from sqlalchemy.orm import Session
from datetime import datetime, timezone, timedelta
from fastapi import HTTPException, status
from typing import List
from app.models.attendance_session import AttendanceSession
from app.schemas.session_schema import SessionOpenRequest
from app.models.class_model import Class as ClassModel
from app.services.location_service import update_teacher_location_log

logger = logging.getLogger(__name__)

def create_attendance_session(
    db: Session, 
    teacher_id: uuid.UUID, 
    session_data: SessionOpenRequest
) -> AttendanceSession:
    """
    สร้าง Session การเช็คชื่อใหม่ และบันทึก Anchor Point ของอาจารย์
    """
    now_utc = datetime.now(timezone.utc)

    # 1. ตรวจสอบ Class ID
    classroom = db.query(ClassModel).filter(ClassModel.class_id == session_data.class_id).first()
    if not classroom:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Classroom not found.")
        
    # 2. ตรวจสอบ Session ซ้ำซ้อน
    existing_active = db.query(AttendanceSession).filter(
        AttendanceSession.class_id == session_data.class_id,
        AttendanceSession.teacher_id == teacher_id,
        AttendanceSession.end_time > now_utc
    ).first()
    if existing_active:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="An active session already exists for this class.")

    # 3. กำหนดเวลาสิ้นสุด (Default 15 นาที)
    session_end_time = session_data.end_time or (now_utc + timedelta(minutes=15))
    if session_end_time <= now_utc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="End time must be in the future.")

    # 4. บันทึก Anchor Point
    new_anchor_log = update_teacher_location_log(
        db=db,
        teacher_id=teacher_id,
        class_id=session_data.class_id,
        latitude=session_data.latitude,
        longitude=session_data.longitude
    )

    # 5. สร้าง Session Record
    new_session = AttendanceSession(
        class_id=session_data.class_id,
        teacher_id=teacher_id,
        start_time=now_utc,
        end_time=session_end_time,
        anchor_lat=new_anchor_log.latitude,
        anchor_lon=new_anchor_log.longitude
    )

    db.add(new_session)
    db.commit()
    db.refresh(new_session)

    logger.info(f"[Session Created] class={session_data.class_id} teacher={teacher_id} end={session_end_time}")
    return new_session


def get_active_sessions(db: Session) -> List[AttendanceSession]:
    """
    ดึงรายการ Sessions ที่กำลังเปิดอยู่และยังไม่หมดอายุ
    """
    current_time = datetime.now(timezone.utc)
    return db.query(AttendanceSession).filter(
        AttendanceSession.end_time > current_time
    ).all()
