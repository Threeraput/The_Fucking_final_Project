from __future__ import annotations
from typing import List, Optional
from uuid import UUID
from datetime import datetime, timezone

from fastapi import HTTPException, status, UploadFile
from sqlalchemy.orm import Session
from sqlalchemy import select

from app.models.classwork import Classwork
from app.models.classwork_enums import SubmissionLateness
from app.utils.pdf_storage import save_pdf_only

def _utcnow() -> datetime:
    return datetime.now(timezone.utc)

def _status_from(due_date: datetime, submitted_at: Optional[datetime]) -> SubmissionLateness:
    if submitted_at is None:
        return SubmissionLateness.NOT_SUBMITTED
    # ทำให้เป็น timezone-aware
    dd = due_date if due_date.tzinfo else due_date.replace(tzinfo=timezone.utc)
    sa = submitted_at if submitted_at.tzinfo else submitted_at.replace(tzinfo=timezone.utc)
    return SubmissionLateness.ON_TIME if sa <= dd else SubmissionLateness.LATE

# ---------- สร้างใบงานแบบพื้นฐาน (1 คน) ----------
def create_assignment(
    db: Session,
    *,
    teacher_id: UUID,
    class_id: UUID,
    student_id: UUID,
    title: str,
    max_score: int,
    due_date: datetime,
) -> Classwork:
    obj = Classwork(
        class_id=class_id,
        teacher_id=teacher_id,
        student_id=student_id,
        title=title,
        max_score=max_score,
        due_date=due_date,
        content_url=None,
        submitted_at=None,
        graded=False,
        score=None,
        submission_status=SubmissionLateness.NOT_SUBMITTED.value
    )
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj

# ---------- ส่งงาน: รับเฉพาะ PDF ----------
async def submit_pdf(
    db: Session,
    *,
    assignment_id: UUID,
    student_id: UUID,
    file: UploadFile,
) -> Classwork:
    obj = db.get(Classwork, assignment_id)
    if not obj:
        raise HTTPException(404, "Assignment not found")
    if obj.student_id != student_id:
        raise HTTPException(403, "Not your assignment")

    saved_path = await save_pdf_only(file)
    now = _utcnow()

    obj.content_url = saved_path
    obj.submitted_at = now
    obj.submission_status = _status_from(obj.due_date, now).value
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj

# ---------- ดูรายการของนักเรียน ----------
def list_my_assignments(
    db: Session,
    *,
    student_id: UUID,
    class_id: Optional[UUID] = None
) -> List[Classwork]:
    q = select(Classwork).where(Classwork.student_id == student_id)
    if class_id:
        q = q.where(Classwork.class_id == class_id)
    q = q.order_by(Classwork.due_date.asc(), Classwork.title.asc())
    return list(db.scalars(q).all())

# ---------- ครูให้คะแนน (พื้นฐาน) ----------
def grade(
    db: Session,
    *,
    assignment_id: UUID,
    teacher_id: UUID,
    score: int
) -> Classwork:
    obj = db.get(Classwork, assignment_id)
    if not obj:
        raise HTTPException(404, "Assignment not found")
    if obj.teacher_id != teacher_id:
        raise HTTPException(403, "Not your assignment (teacher)")

    if score < 0 or score > obj.max_score:
        raise HTTPException(400, f"Score must be between 0 and {obj.max_score}")

    obj.score = score
    obj.graded = True
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj
