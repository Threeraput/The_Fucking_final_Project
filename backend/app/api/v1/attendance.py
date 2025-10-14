# backend/app/api/v1/attendance.py
import uuid
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Response, Path, Body
from sqlalchemy.orm import Session, joinedload

from app.database import get_db
from app.models.user import User
from app.models.attendance import Attendance  # <-- Add this import
from app.schemas.attendance_schema import (
    AttendanceCheckIn,
    AttendanceResponse,
    TeacherLocationUpdate,
    StudentLocationLogCreate,
    AttendanceManualOverride,
    ReverifyRequest, 
)
# ใช้อันเดียวให้ตรงทั้งโปรเจกต์
from app.core.deps import get_current_user  # <- ถ้าคุณใช้ของ core.deps อยู่ที่อื่น
from app.services.attendance_service import record_check_in , handle_reverification , manual_override_attendance
from app.services.location_service import update_teacher_location_log, log_student_location

router = APIRouter(prefix="/attendance", tags=["Attendance"])


def _has_role(user: User, role_name: str) -> bool:
    # ปลอดภัยแม้ roles เป็น lazy-loaded
    try:
        return any(getattr(r, "name", None) == role_name for r in (user.roles or []))
    except Exception:
        return False


# ------------------------------------
# 1. POST /attendance/check-in (Student: Face ID + Proximity Check)
# ------------------------------------
@router.post("/check-in", response_model=AttendanceResponse)
async def check_in(
    # ใช้ as_form เพื่อให้ FastAPI ดึงค่าจาก multipart/form-data
    class_data: AttendanceCheckIn = Depends(AttendanceCheckIn.as_form),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    นักเรียนเช็คชื่อเข้าเรียนด้วยใบหน้าและตำแหน่ง (Proximity Check).
    """
    if "student" not in [role.name for role in current_user.roles]:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only students can check in.")

    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid file type. Only images are allowed.")

    image_bytes = await file.read()

    #  เปลี่ยนมาใช้ session_id ตามการออกแบบล่าสุด
    attendance_record = record_check_in(
        db=db,
        session_id=class_data.session_id,
        student_id=current_user.user_id,
        image_bytes=image_bytes,
        student_lat=class_data.latitude,
        student_lon=class_data.longitude,
    )
    return attendance_record


# ------------------------------------
# 2. POST /attendance/teacher-location (Teacher: อัปเดต Anchor Point)
# ------------------------------------
@router.post("/teacher-location", status_code=status.HTTP_200_OK)
async def update_teacher_location(
    location_data: TeacherLocationUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    อาจารย์อัปเดตพิกัดล่าสุดของตนเองสำหรับ Relative Geofencing.
    """
    if not _has_role(current_user, "teacher"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only teachers can update their location.")

    update_teacher_location_log(
        db=db,
        teacher_id=current_user.user_id,
        class_id=location_data.class_id,
        latitude=location_data.latitude,
        longitude=location_data.longitude,
    )
    return {"message": "Teacher location updated successfully."}


# ------------------------------------
# 3. POST /attendance/student-tracking (Student: ส่งพิกัดต่อเนื่อง)
# ------------------------------------
@router.post("/student-tracking", status_code=status.HTTP_200_OK)
async def track_student_location(
    log_data: StudentLocationLogCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    บันทึกตำแหน่งของนักเรียนอย่างต่อเนื่องระหว่างคาบเรียน (Continuous Tracking).
    """
    if not _has_role(current_user, "student"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only students can track location.")

    # (optional) rate-limit/debounce ตาม user+class (กัน spam insert)
    # enforce_min_interval(db, current_user.user_id, log_data.class_id, seconds=10)

    log_student_location(
        db=db,
        student_id=current_user.user_id,
        class_id=log_data.class_id,
        latitude=log_data.latitude,
        longitude=log_data.longitude,
    )
    return {"message": "Student location logged successfully."}


# ------------------------------------
# 4. POST /attendance/re-verify (Student: ตอบสนองต่อการสุ่มตรวจซ้ำ)
# ------------------------------------
@router.post("/re-verify", response_model=AttendanceResponse, status_code=status.HTTP_200_OK)
async def re_verify_check_in(
    form: ReverifyRequest = Depends(ReverifyRequest.as_form),  # ← อ่านจาก multipart/form-data
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    นักเรียนตอบสนองต่อคำสั่งสุ่มตรวจสอบกลางคาบเรียน (Face ID + Location).
    """
    if "student" not in [role.name for role in current_user.roles]:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")

    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Invalid file type. Only images are allowed.")

    image_bytes = await file.read()

    result = handle_reverification(
        db=db,
        session_id=form.session_id,           # ← ใช้ session_id (ไม่ใช่ class_id)
        student_id=current_user.user_id,
        image_bytes=image_bytes,
        student_lat=form.latitude,
        student_lon=form.longitude,
    )

    # ส่งคืนตาม schema ของคุณ (ถ้า AttendanceResponse ใช้ from_orm / model_validate)
    try:
        return AttendanceResponse.model_validate(result, from_attributes=True)
    except Exception:
        return AttendanceResponse.from_orm(result)

# ------------------------------------
# 5. PATCH /attendance/override/{attendance_id} (Teacher/Admin Only)
# ------------------------------------
@router.patch("/override/{attendance_id}", response_model=AttendanceResponse)
async def override_attendance_status(
    attendance_id: uuid.UUID = Path(..., description="UUID of the attendance record to override"),
    override_data: AttendanceManualOverride = Body(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    แก้ไขสถานะการเข้าเรียนด้วยมือ (Manual Override) โดย Teacher หรือ Admin.
    """

    roles = {r.name for r in getattr(current_user, "roles", [])}
    is_admin = "admin" in roles
    is_teacher = "teacher" in roles

    if not (is_admin or is_teacher):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied. Only teachers or admins can modify attendance records.",
        )

    # ถ้าเป็นครู (ไม่ใช่แอดมิน) ต้องเป็นครูเจ้าของคลาสของ attendance record นี้เท่านั้น
    if is_teacher and not is_admin:
        att = (
            db.query(Attendance)
            .options(joinedload(Attendance.class_rel))  # ดึงคลาสมาด้วย
            .filter(Attendance.attendance_id == attendance_id)
            .first()
        )
        if not att:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Attendance not found.")
        if att.class_rel.teacher_id != current_user.user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only modify attendance for your own class."
            )

    # เรียก service (ภายในควร normalize enum -> string .value ให้ตรงกับ DB)
    record = manual_override_attendance(
        db=db,
        attendance_id=attendance_id,
        new_status=override_data.status,           # ให้ service จัดการ normalize
        recorded_by_user_id=current_user.user_id,
    )

    # แปลง ORM -> Pydantic ให้ตรง response_model
    try:
        return AttendanceResponse.model_validate(record, from_attributes=True)  # Pydantic v2
    except Exception:
        return AttendanceResponse.from_orm(record)  # fallback Pydantic v1