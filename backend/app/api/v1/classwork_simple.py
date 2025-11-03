from typing import List, Optional
from uuid import UUID
from datetime import datetime

from fastapi import APIRouter, Depends, UploadFile, File, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError

from app.database import get_db
from app.core.deps import get_current_user
from app.models.user import User
from app.schemas.classwork_schema import ClassworkResponse, SubmissionResponse
from app.services.simple_classwork_service import (
    create_assignment, submit_pdf, list_my_assignments, grade
)

# ใช้ association table ที่คุณมีอยู่แล้ว
from app.models.association import class_students

router = APIRouter(prefix="/classwork-simple", tags=["Classwork (Simple)"])

# -------------------------
# Role helpers (อยู่ในไฟล์นี้เท่านั้น)
# -------------------------
def _to_name(x):
    return getattr(x, "name", x)

def _has_role(user: User, role: str) -> bool:
    roles = getattr(user, "roles", []) or []
    want = role.lower()
    return any(str(_to_name(r)).lower() == want for r in roles)

def _is_admin(user: User) -> bool:
    return _has_role(user, "admin")

def _require_teacher(user: User):
    if not (_has_role(user, "teacher") or _is_admin(user)):
        raise HTTPException(status_code=403, detail="Only teachers can perform this action.")

def _require_student(user: User):
    if not (_has_role(user, "student") or _is_admin(user)):
        raise HTTPException(status_code=403, detail="Only students can perform this action.")

# -------------------------
# Endpoints
# -------------------------

# ✅ ครูสร้างงานให้ "ทั้งคลาส": สร้างแถวงานให้ทุก student ในคลาส
@router.post("/create/class/{class_id}", response_model=dict, status_code=status.HTTP_201_CREATED)
def create_assignments_for_class(
    class_id: UUID,
    title: str,
    max_score: int,
    due_date: str,  # ISO 8601: '2025-11-04T12:00:00+07:00'
    db: Session = Depends(get_db),
    me: User = Depends(get_current_user),
):
    _require_teacher(me)

    # parse due_date
    try:
        due = datetime.fromisoformat(due_date)
    except ValueError:
        raise HTTPException(status_code=422, detail="Invalid due_date format (must be ISO 8601)")

    # ดึง student ทั้งหมดของคลาสจาก association table
    rows = db.execute(
        select(class_students.c.student_id).where(class_students.c.class_id == class_id)
    ).all()
    student_ids = [r[0] for r in rows]

    if not student_ids:
        return {"created": [], "skipped": [], "message": "No students in this class."}

    created: List[str] = []
    skipped: List[str] = []

    for sid in student_ids:
        try:
            obj = create_assignment(
                db,
                teacher_id=me.user_id,
                class_id=class_id,
                student_id=sid,
                title=title,
                max_score=max_score,
                due_date=due,
            )
            created.append(str(obj.assignment_id))
        except HTTPException as e:
            # เผื่อ service โยน 409 (duplicate) ออกมา
            if e.status_code == 409:
                skipped.append(str(sid))
                continue
            raise
        except IntegrityError:
            # เผื่อ unique (class_id, student_id, title) ซ้ำ
            db.rollback()
            skipped.append(str(sid))
            continue

    return {"created": created, "skipped": skipped, "total_students": len(student_ids)}

# (ยังคงไว้) ครูสร้างงานให้ "รายคน" เผื่อใช้เฉพาะกิจ
@router.post("/create/{student_id}", response_model=SubmissionResponse, status_code=status.HTTP_201_CREATED)
def create_one_assignment(
    student_id: UUID,
    title: str,
    max_score: int,
    class_id: UUID,
    due_date: str,
    db: Session = Depends(get_db),
    me: User = Depends(get_current_user),
):
    _require_teacher(me)

    try:
        due = datetime.fromisoformat(due_date)
    except ValueError:
        raise HTTPException(status_code=422, detail="Invalid due_date format (must be ISO 8601)")

    obj = create_assignment(
        db,
        teacher_id=me.user_id,
        class_id=class_id,
        student_id=student_id,
        title=title,
        max_score=max_score,
        due_date=due,
    )
    return obj

# นักเรียนส่งงาน (เฉพาะ PDF)
@router.post("/{assignment_id}/submit", response_model=SubmissionResponse)
async def submit_assignment_pdf(
    assignment_id: UUID,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    me: User = Depends(get_current_user),
):
    _require_student(me)
    obj = await submit_pdf(
        db,
        assignment_id=assignment_id,
        student_id=me.user_id,
        file=file
    )
    return obj

# นักเรียนดูรายการงานของตัวเอง
@router.get("/student/my", response_model=List[SubmissionResponse])
def my_assignments(
    class_id: Optional[UUID] = None,
    db: Session = Depends(get_db),
    me: User = Depends(get_current_user),
):
    _require_student(me)
    return list_my_assignments(db, student_id=me.user_id, class_id=class_id)

# ครูให้คะแนนแบบพื้นฐาน
@router.post("/{assignment_id}/grade", response_model=SubmissionResponse)
def grade_assignment(
    assignment_id: UUID,
    score: int,
    db: Session = Depends(get_db),
    me: User = Depends(get_current_user),
):
    _require_teacher(me)
    obj = grade(
        db,
        assignment_id=assignment_id,
        teacher_id=me.user_id,
        score=score
    )
    return obj
