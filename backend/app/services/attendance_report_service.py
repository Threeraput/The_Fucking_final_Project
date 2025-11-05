from sqlalchemy.orm import Session
from datetime import datetime
from app.models.attendance import Attendance
from app.models.attendance_session import AttendanceSession
from app.models.attendance_report import AttendanceReport
from app.models.attendance_report_detail import AttendanceReportDetail
from app.models.association import class_students


def generate_reports_for_class(db: Session, class_id: str):
    """สร้างรายงานการเช็คชื่อรายคนในคลาสนั้น"""
    db.query(AttendanceReport).filter(AttendanceReport.class_id == class_id).delete()
    db.commit()

    # ดึงนักเรียนทั้งหมดในคลาส
    student_rows = db.execute(
        class_students.select().where(class_students.c.class_id == class_id)
    ).fetchall()
    student_ids = [row.student_id for row in student_rows]

    # ดึง sessions ทั้งหมดในคลาส
    sessions = db.query(AttendanceSession).filter(
        AttendanceSession.class_id == class_id
    ).all()
    total_sessions = len(sessions)

    for student_id in student_ids:
        attended = late = absent = left_early = reverified = 0

        report = AttendanceReport(
            class_id=class_id,
            student_id=student_id,
            total_sessions=total_sessions,
            generated_at=datetime.utcnow(),
        )
        db.add(report)
        db.flush()  # เพื่อให้ได้ report_id ก่อนสร้าง detail

        for session in sessions:
            record = (
                db.query(Attendance)
                .filter(
                    Attendance.class_id == class_id,
                    Attendance.session_id == session.session_id,
                    Attendance.student_id == student_id,
                )
                .first()
            )

            # ไม่มี record = ขาด
            if not record:
                absent += 1
                db.add(
                    AttendanceReportDetail(
                        report_id=report.report_id,
                        session_id=session.session_id,
                        status="Absent",
                        check_in_time=None,
                        is_reverified=False,
                    )
                )
                continue

            # เช็คชื่อแล้ว
            if not record.is_reverified:
                left_early += 1
                status = "LeftEarly"
            else:
                status = record.status
                if status == "Present":
                    attended += 1
                elif status == "Late":
                    late += 1
                elif status == "Absent":
                    absent += 1

            if record.is_reverified:
                reverified += 1

            db.add(
                AttendanceReportDetail(
                    report_id=report.report_id,
                    session_id=session.session_id,
                    check_in_time=record.check_in_time,
                    status=status,
                    is_reverified=record.is_reverified,
                )
            )

        report.attended_sessions = attended
        report.late_sessions = late
        report.absent_sessions = absent
        report.left_early_sessions = left_early
        report.reverified_sessions = reverified
        report.attendance_rate = (
            ((attended + late) / total_sessions) * 100 if total_sessions > 0 else 0
        )

    db.commit()
    return {"message": f"✅ Generated reports for {len(student_ids)} students in class {class_id}"}
