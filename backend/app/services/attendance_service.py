# backend/app/services/attendance_service.py
import io
import uuid
from datetime import datetime, timezone, timedelta
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.attendance import Attendance
from app.models.attendance_enums import AttendanceStatus
from app.models.class_model import Class as ClassModel
from app.models.attendance_session import AttendanceSession
from app.schemas.attendance_schema import AttendanceResponse
from app.services.face_recognition_service import get_face_embedding, compare_faces
from app.services.location_service import (
    is_within_proximity,
    get_latest_teacher_location,
)

# ---------------------------
# Helpers
# ---------------------------
def _today_range_utc() -> tuple[datetime, datetime]:
    """ช่วงเวลาเริ่ม-จบของ 'วันนี้' (UTC) สำหรับกันเช็คชื่อซ้ำ"""
    now = datetime.now(timezone.utc)
    start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    end = start + timedelta(days=1)
    return start, end

def _ensure_aware_utc(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)

def decide_status_by_hard_times(
    start: datetime,
    late_cutoff: datetime,
    end: datetime,
    now: datetime | None = None,
) -> AttendanceStatus:
    now = _ensure_aware_utc(now or datetime.now(timezone.utc))
    s = _ensure_aware_utc(start)
    l = _ensure_aware_utc(late_cutoff)
    e = _ensure_aware_utc(end)

    if now > e:
        return AttendanceStatus.ABSENT
    if now < s:
        return AttendanceStatus.PRESENT  
    if (now >= s and now < l):
        return AttendanceStatus.PRESENT
    if (now >= l and now < e):
        return AttendanceStatus.LATE
    
    return AttendanceStatus.ABSENT


# ---------------------------
# Main
# ---------------------------
def record_check_in(
    db: Session,
    session_id: uuid.UUID,
    student_id: uuid.UUID,
    image_bytes: bytes,
    student_lat: float,
    student_lon: float,
) -> AttendanceResponse:
    # 1) โหลด session
    session = (
        db.query(AttendanceSession)
        .filter(AttendanceSession.session_id == session_id)
        .first()
    )
    if not session:
        raise HTTPException(status_code=404, detail="Attendance session not found.")

    now = datetime.now(timezone.utc)
    # ปิดหน้าต่างเช็คอินทันทีหากพ้น end_time
    if now > _ensure_aware_utc(session.end_time):
        raise HTTPException(status_code=400, detail="Check-in window for this session has closed.")

    # 2) ตรวจระยะ anchor point
    t_lat = float(session.anchor_lat); t_lon = float(session.anchor_lon)
    if not is_within_proximity(student_lat, student_lon, t_lat, t_lon):
        raise HTTPException(status_code=403, detail="Location check failed. You are too far from the classroom teacher.")

    # 3) Face verification (เหมือนเดิม)
    if not image_bytes:
        raise HTTPException(status_code=400, detail="Image is required for check-in.")
    try:
        embedding = get_face_embedding(io.BytesIO(image_bytes))
        is_face_verified = compare_faces(db, student_id, embedding)
    except HTTPException:
        raise
    except Exception:
        is_face_verified = False

    # 4) กันเช็คซ้ำภายใน session
    already = (
        db.query(Attendance)
        .filter(
            Attendance.session_id == session_id,
            Attendance.student_id == student_id,
        )
        .first()
    )
    if already:
        raise HTTPException(status_code=409, detail="Attendance already recorded for this session.")

    # 5) สถานะตาม 3 จุดเวลา
    status_to_record = AttendanceStatus.UNVERIFIED_FACE
    if is_face_verified:
        status_to_record = decide_status_by_hard_times(
            session.start_time, session.late_cutoff_time, session.end_time, now=now
        )

    # 6) บันทึก
    new_attendance = Attendance(
        class_id=session.class_id,
        session_id=session.session_id,
        student_id=student_id,
        status=status_to_record,
        check_in_lat=student_lat,
        check_in_lon=student_lon,
    )
    try:
        db.add(new_attendance)
        db.commit()
        db.refresh(new_attendance)
    except Exception:
        db.rollback()
        raise

    # schema
    try:
        return AttendanceResponse.model_validate(new_attendance, from_attributes=True)
    except Exception:
        return AttendanceResponse.from_orm(new_attendance)


def handle_reverification(
    db: Session,
    session_id: uuid.UUID,
    student_id: uuid.UUID,
    image_bytes: bytes,
    student_lat: float,
    student_lon: float,
) -> Attendance:
    """
    จัดการการสุ่มตรวจซ้ำ (Re-Verification) ระหว่าง session ที่เปิดอยู่
    - ยืนยันว่ามี attendance วันนี้ใน session เดียวกัน
    - ตรวจระยะห่างจาก anchor ของ session
    - ยืนยันใบหน้า
    - อัปเดตสถานะ (ไม่เขียนทับเวลาของการเช็คอินครั้งแรก)
    """

    # 1) ตรวจสอบ Session
    session = db.query(AttendanceSession).filter(
        AttendanceSession.session_id == session_id
    ).first()
    if not session:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Attendance session not found.")

    # (เลือกได้) บังคับให้ re-verify ได้เฉพาะช่วงที่ session ยังไม่หมดอายุ
    if session.end_time and datetime.now(timezone.utc) > session.end_time:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Re-verification window has closed for this session.")

    # 2) หา attendance วันนี้ของนักเรียนใน session นี้
    start_today, end_today = _today_range_utc()
    attendance = (
        db.query(Attendance)
        .filter(
            Attendance.session_id == session_id,
            Attendance.student_id == student_id,
            Attendance.check_in_time >= start_today,
            Attendance.check_in_time < end_today,
        )
        .order_by(Attendance.check_in_time.desc())
        .first()
    )

    if not attendance or attendance.status in (AttendanceStatus.ABSENT, AttendanceStatus.LEFT_EARLY):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No active attendance to re-verify, or status already finalized."
        )

    # 3) ตรวจ Proximity เทียบกับ anchor ของ session
    # anchor_lat/lon เป็น Numeric(9,6) -> แปลงเป็น float
    anchor_lat = float(session.anchor_lat)
    anchor_lon = float(session.anchor_lon)

    # ระยะอย่างง่าย (ไม่มี dependency geopy):  ~111,000 m ต่อ 1 องศา
    def _approx_distance_m(lat1, lon1, lat2, lon2) -> float:
        return ((lat1-lat2)**2 + ((lon1-lon2) * 0.92)**2) ** 0.5 * 111_000

    if _approx_distance_m(student_lat, student_lon, anchor_lat, anchor_lon) > 20.0:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Location check failed during re-verification.")

    # 4) Face verification
    if not image_bytes:
        raise HTTPException(status_code=400, detail="Image is required for re-verification.")
    try:
        new_embedding = get_face_embedding(io.BytesIO(image_bytes))
        is_face_verified = compare_faces(db, student_id, new_embedding)
    except HTTPException:
        raise
    except Exception:
        is_face_verified = False

    # 5) อัปเดตสถานะ
    if not is_face_verified:
        attendance.status = AttendanceStatus.LEFT_EARLY
        attendance.is_reverified = True  # ยังถือว่าได้ทำ re-verify แล้ว แต่ไม่ผ่าน
    else:
        attendance.is_reverified = True
        # แนะนำไม่แก้ check_in_time; ถ้าต้องการ timestamp ของ re-verify ให้เพิ่มคอลัมน์ reverified_at ในภายหลัง
        # attendance.reverified_at = datetime.now(timezone.utc)  # (ถ้ามีคอลัมน์นี้)

    db.add(attendance)
    db.commit()
    db.refresh(attendance)
    return attendance

def manual_override_attendance(
    db: Session, 
    attendance_id: uuid.UUID, 
    new_status: AttendanceStatus,
    recorded_by_user_id: uuid.UUID
) -> AttendanceResponse:
    """
    แก้ไขสถานะการเข้าเรียนด้วยมือ (Manual Override).
    """
    attendance = db.query(Attendance).filter(Attendance.attendance_id == attendance_id).first()
    
    if not attendance:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Attendance record not found.")

    # 1. ตรวจสอบสิทธิ์ (Optional: ตรวจสอบความเป็น Teacher/Admin ใน API)
    
    # 2. ตั้งค่าสถานะใหม่
    attendance.status = new_status
    attendance.is_manual_override = True  # บันทึกว่าถูกแก้ไขด้วยมือ
    attendance.recorded_by_user_id = recorded_by_user_id
    
    try:
        db.commit()
        db.refresh(attendance)
        return AttendanceResponse.from_orm(attendance)
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Failed to save manual override: {e}")