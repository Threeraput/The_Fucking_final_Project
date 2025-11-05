from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.services.attendance_report_service import generate_reports_for_class
from app.models.attendance_report import AttendanceReport
from app.schemas.attendance_report_schema import AttendanceReportResponse
from app.core.deps import get_current_user, role_required

router = APIRouter(prefix="/attendance/reports", tags=["Attendance Reports"])


@router.post("/{class_id}/generate", response_model=dict, dependencies=[Depends(role_required(["teacher"]))])
def generate_class_reports(class_id: str, db: Session = Depends(get_db), me=Depends(get_current_user)):
    """สร้างรายงานการเช็คชื่อของคลาส"""
    return generate_reports_for_class(db, class_id)


@router.get("/{class_id}", response_model=list[AttendanceReportResponse], dependencies=[Depends(get_current_user)])
def get_class_reports(class_id: str, db: Session = Depends(get_db)):
    """ดูรายงานของคลาสนั้น ๆ"""
    reports = db.query(AttendanceReport).filter(AttendanceReport.class_id == class_id).all()
    return reports
