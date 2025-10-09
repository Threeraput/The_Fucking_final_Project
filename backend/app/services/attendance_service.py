# backend/app/services/attendance_service.py
import io
import uuid
from datetime import datetime, timezone, timedelta

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.attendance import Attendance
from app.models.attendance_enums import AttendanceStatus
from app.models.class_model import Class as ClassModel
from app.schemas.attendance_schema import AttendanceResponse
from app.services.face_recognition_service import get_face_embedding, compare_faces
from app.services.location_service import (
    is_within_proximity,
    get_latest_teacher_location,
)

# ---------------------------
# Helpers
# ---------------------------
def _normalize_status(value) -> str:
    """รีเทิร์นค่า string (.value) ที่ตรงกับ enum ใน DB เสมอ"""
    if isinstance(value, AttendanceStatus):
        return value.value
    if isinstance(value, str):
        # รองรับกรณีส่งมาเป็น "PRESENT"
        try:
            return AttendanceStatus[value].value
        except KeyError:
            return value  # เป็น "Present" อยู่แล้ว
    raise ValueError("Invalid status type")

def _ensure_aware_utc(dt: datetime | None) -> datetime | None:
    """ทำให้ datetime เป็น timezone-aware (UTC) เสมอ เพื่อเทียบเวลาได้ถูกต้อง"""
    if dt is None:
        return None
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)

def calculate_attendance_status(class_start_time: datetime) -> AttendanceStatus:
    """คำนวณสถานะการเข้าเรียน (Present/Late/Absent) เทียบกับเวลาเริ่มคลาส (UTC)"""
    current_time = datetime.now(timezone.utc)
    class_start_time = _ensure_aware_utc(class_start_time)

    LATE_THRESHOLD_MINUTES = 15
    late_threshold_time = class_start_time + timedelta(minutes=LATE_THRESHOLD_MINUTES)

    if current_time <= class_start_time:
        return AttendanceStatus.PRESENT
    elif current_time <= late_threshold_time:
        return AttendanceStatus.LATE
    else:
        return AttendanceStatus.ABSENT

def _today_range_utc() -> tuple[datetime, datetime]:
    """ช่วงเวลาเริ่ม-จบของ 'วันนี้' (UTC) สำหรับกันเช็คชื่อซ้ำ"""
    now = datetime.now(timezone.utc)
    start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    end = start + timedelta(days=1)
    return start, end

# ---------------------------
# Main
# ---------------------------
def record_check_in(
    db: Session,
    class_id: uuid.UUID,
    student_id: uuid.UUID,
    image_bytes: bytes,
    student_lat: float,
    student_lon: float,
) -> AttendanceResponse:
    """
    ขั้นตอน:
    1) ตรวจสอบคลาส
    2) ดึงพิกัดล่าสุดของครู (anchor)
    3) ตรวจ proximity (นักเรียนใกล้ครู)
    4) Face verification
    5) กันเช็คซ้ำภายในวันเดียวกัน (UTC)
    6) คำนวณสถานะและบันทึก Attendance
    """

    # 1) ตรวจสอบ Class
    classroom = db.query(ClassModel).filter(ClassModel.class_id == class_id).first()
    if not classroom:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Classroom not found.")

    # 2) พิกัดครูล่าสุด
    teacher_location = get_latest_teacher_location(db, classroom.teacher_id, class_id)

    # Numeric(9,6) -> Decimal; แปลงเป็น float
    t_lat = float(teacher_location.latitude)
    t_lon = float(teacher_location.longitude)

    # 3) ตรวจ proximity
    if not is_within_proximity(student_lat, student_lon, t_lat, t_lon):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Location check failed. You are too far from the classroom teacher.",
        )

    # 4) Face verification (ต้องมีรูป)
    if not image_bytes:
        raise HTTPException(status_code=400, detail="Image is required for check-in.")

    try:
        new_embedding = get_face_embedding(io.BytesIO(image_bytes))
        is_face_verified = compare_faces(db, student_id, new_embedding)
    except HTTPException:
        # ส่งต่อ error จาก face service เช่น "No face detected"
        raise
    except Exception:
        # ผิดพลาดไม่คาดคิด -> ถือว่าไม่ผ่าน จะได้ไม่เกิด false positive
        is_face_verified = False

    # 5) กันเช็คซ้ำภายใน "วันเดียวกัน" (UTC)
    start_today, end_today = _today_range_utc()
    already = (
        db.query(Attendance)
        .filter(
            Attendance.class_id == class_id,
            Attendance.student_id == student_id,
            Attendance.check_in_time >= start_today,
            Attendance.check_in_time < end_today,
        )
        .first()
    )
    if already:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Attendance already recorded for today.",
        )

    # 6) คำนวณสถานะ
    status_to_record = AttendanceStatus.UNVERIFIED_FACE
    if is_face_verified:
        start_time_utc = _ensure_aware_utc(classroom.start_time)
        status_to_record = (
            calculate_attendance_status(start_time_utc)
            if start_time_utc
            else AttendanceStatus.PRESENT
        )

    # สร้างค่า status เป็น string ที่ DB ยอมรับแน่นอน
    status_str = _normalize_status(status_to_record)

    # Insert
    new_attendance = Attendance(
        class_id=class_id,
        student_id=student_id,
        status=status_str,           # ← 'Present'/'Late'/... (ไม่ใช่ 'PRESENT')
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

    # Pydantic v2/v1
    try:
        return AttendanceResponse.model_validate(new_attendance, from_attributes=True)
    except Exception:
        return AttendanceResponse.from_orm(new_attendance)
    

def handle_reverification(
    db: Session, 
    class_id: uuid.UUID, 
    student_id: uuid.UUID, 
    image_bytes: bytes, 
    student_lat: float, 
    student_lon: float
) -> Attendance:
    """
    จัดการการตอบสนองต่อคำสั่งสุ่มตรวจสอบ (Re-Verification).
    """
    # 1. ตรวจสอบว่านักเรียนได้เช็คอินแล้ววันนี้
    existing_attendance = db.query(Attendance).filter(
        Attendance.class_id == class_id,
        Attendance.student_id == student_id
        # (เพิ่ม Logic ตรวจสอบว่าเป็นการเข้าเรียนในวันเดียวกันหรือไม่)
    ).order_by(Attendance.check_in_time.desc()).first()

    if not existing_attendance or existing_attendance.status in [AttendanceStatus.ABSENT, AttendanceStatus.LEFT_EARLY]:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="You have not checked in to this class yet, or your status is already finalized.")

    # 2. ตรวจสอบ Location Proximity (ซ้ำ)
    classroom = existing_attendance.class_rel
    teacher_location = get_latest_teacher_location(db, classroom.teacher_id, class_id)
    if not is_within_proximity(student_lat, student_lon, teacher_location.latitude, teacher_location.longitude):
         raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Location check failed during re-verification.")

    # 3. ยืนยันใบหน้า (Face Verification Logic)
    try:
        new_embedding = get_face_embedding(io.BytesIO(image_bytes))
        is_face_verified = compare_faces(db, student_id, new_embedding)
    except HTTPException as e:
        raise e 
    
    if not is_face_verified:
        # ถ้า Face Verification ล้มเหลว ให้ตั้งสถานะเป็น Left_Early/Absent ทันที
        existing_attendance.status = AttendanceStatus.LEFT_EARLY
        
    else:
        # 4. ถ้าทุกอย่างผ่าน ให้อัปเดตสถานะการยืนยันซ้ำ
        existing_attendance.is_reverified = True
    
    existing_attendance.check_in_time = datetime.now(timezone.utc) # อัปเดตเวลาล่าสุด
    db.commit()
    db.refresh(existing_attendance)
    
    return existing_attendance

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