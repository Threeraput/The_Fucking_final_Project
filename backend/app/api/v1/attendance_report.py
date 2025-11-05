from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.core.deps import get_current_user, role_required
from app.models.user import User
from app.models.attendance_report import AttendanceReport
from app.schemas.attendance_report_schema import AttendanceReportResponse
from app.services.attendance_report_service import generate_reports_for_class


router = APIRouter(prefix="/attendance/reports", tags=["Attendance Reports"])


# ---------- นักเรียน ----------
@router.get("/my-report", response_model=list[AttendanceReportResponse])
def get_my_report(
    db: Session = Depends(get_db),
    me: User = Depends(get_current_user),
):
    """นักเรียนดูรายงานของตัวเอง"""

    # ✅ ตรวจสิทธิ์: User ต้องมี role "student" ใน me.roles
    if not any(r.name == "student" for r in me.roles):
        raise HTTPException(
            status_code=403,
            detail="Only students can view their own report"
        )

    # ✅ ดึงรายงานของนักเรียนตาม user_id
    reports = db.query(AttendanceReport).filter(
        AttendanceReport.student_id == me.user_id
    ).all()

    if not reports:
        raise HTTPException(
            status_code=404,
            detail="No reports found for this user"
        )

    return reports


# ---------- ครู ----------
@router.post(
    "/class/{class_id}/generate",
    response_model=dict,
    dependencies=[Depends(role_required(["teacher"]))],
)
def generate_class_reports(class_id: str, db: Session = Depends(get_db)):
    """ครูสร้างรายงานทั้งคลาส"""
    return generate_reports_for_class(db, class_id)


@router.get(
    "/class/{class_id}",
    response_model=list[AttendanceReportResponse],
    dependencies=[Depends(role_required(["teacher"]))],
)
def get_class_reports(class_id: str, db: Session = Depends(get_db)):
    """ครูดูรายงานรวมของคลาส"""
    reports = db.query(AttendanceReport).filter(
        AttendanceReport.class_id == class_id
    ).all()
    return reports


@router.get(
    "/class/{class_id}/summary",
    response_model=dict,
    dependencies=[Depends(role_required(["teacher"]))],
)
def get_class_summary(class_id: str, db: Session = Depends(get_db)):
    """สรุปรายงานรวมของคลาส"""
    reports = db.query(AttendanceReport).filter(
        AttendanceReport.class_id == class_id
    ).all()

    if not reports:
        raise HTTPException(
            status_code=404,
            detail="No reports found for this class"
        )

    avg_rate = sum(r.attendance_rate for r in reports) / len(reports)
    total_students = len(reports)
    total_absent = sum(r.absent_sessions for r in reports)

    return {
        "class_id": class_id,
        "total_students": total_students,
        "average_attendance_rate": round(avg_rate, 2),
        "total_absent_records": total_absent,
    }


@router.get(
    "/student/{student_id}",
    response_model=list[AttendanceReportResponse],
    dependencies=[Depends(role_required(["teacher"]))],
)
def get_student_report(student_id: str, db: Session = Depends(get_db)):
    """ครูดูรายงานของนักเรียนรายคน"""
    reports = db.query(AttendanceReport).filter(
        AttendanceReport.student_id == student_id
    ).all()

    if not reports:
        raise HTTPException(
            status_code=404,
            detail="No report found for this student"
        )

    return reports
