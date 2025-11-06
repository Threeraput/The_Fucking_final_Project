from fastapi import APIRouter, Depends, HTTPException, status, Path, Query
from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import func, or_
import uuid
from datetime import datetime

from app.database import get_db
from app.schemas.user_schema import UserResponse
from app.schemas.admin_schema import AdminUsersPage, SystemSummaryReport, AdminClassesPage, AdminClassSummary
from app.models.user import User
from app.models.role import Role
from app.models.class_model import Class as ClassModel
from app.models.attendance import Attendance
from app.models.association import user_roles
# ✅ เพิ่ม import ตารางนักเรียนในคลาส (association table)
from app.models.association import class_students
from app.services.db_service import approve_teacher
from app.core.deps import get_current_admin_user

router = APIRouter(prefix="/admin", tags=["Admin"])

@router.get("/status", response_model=dict)
async def get_admin_status(current_user: User = Depends(get_current_admin_user)):
    return {"message": f"Admin endpoint is working! Welcome, {current_user.username}."}

@router.post("/users/{user_id}/approve-teacher", response_model=UserResponse)
async def approve_user_as_teacher(
    user_id: uuid.UUID = Path(..., description="The UUID of the teacher user to approve"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin_user)
):
    approved_user = approve_teacher(db, user_id)
    if not approved_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found or is not a teacher."
        )
    user_roles = [role.name for role in approved_user.roles]
    return UserResponse(
        user_id=approved_user.user_id,
        username=approved_user.username,
        first_name=approved_user.first_name,
        last_name=approved_user.last_name,
        email=approved_user.email,
        is_active=approved_user.is_active,
        is_approved=getattr(approved_user, "is_approved", None),
        created_at=approved_user.created_at,
        updated_at=approved_user.updated_at,
        last_login_at=approved_user.last_login_at,
        roles=user_roles
    )

@router.get("/pending-teachers", response_model=List[UserResponse])
async def get_pending_teachers(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin_user)
):
    pending_teachers = db.query(User).filter(User.is_approved == False).all()
    response_list: List[UserResponse] = []
    for user in pending_teachers:
        user_roles = [role.name for role in user.roles]
        response_list.append(
            UserResponse(
                user_id=user.user_id,
                username=user.username,
                first_name=user.first_name,
                last_name=user.last_name,
                email=user.email,
                is_active=user.is_active,
                is_approved=getattr(user, "is_approved", None),
                created_at=user.created_at,
                updated_at=user.updated_at,
                last_login_at=user.last_login_at,
                roles=user_roles
            )
        )
    return response_list

# ===========================
# ✅ NEW: Admin - List all users (with search, role filter, pagination)
# ===========================
@router.get("/users", response_model=AdminUsersPage)
async def admin_list_users(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin_user),
    q: Optional[str] = Query(None, description="search by username/email/first/last name"),
    role: Optional[str] = Query(None, description="filter by role: admin|teacher|student"),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
):
    query = db.query(User)

    if q:
        like = f"%{q.strip()}%"
        query = query.filter(or_(
            User.username.ilike(like),
            User.email.ilike(like),
            User.first_name.ilike(like),
            User.last_name.ilike(like),
        ))

    if role:
        rl = role.strip().lower()
        query = query.join(User.roles).filter(func.lower(Role.name) == rl)

    total = query.count()
    rows = (
        query
        .order_by(User.created_at.desc())
        .limit(limit)
        .offset(offset)
        .all()
    )

    items: List[UserResponse] = []
    for u in rows:
        items.append(
            UserResponse(
                user_id=u.user_id,
                username=u.username,
                first_name=u.first_name,
                last_name=u.last_name,
                email=u.email,
                is_active=u.is_active,
                is_approved=getattr(u, "is_approved", None),
                created_at=u.created_at,
                updated_at=u.updated_at,
                last_login_at=u.last_login_at,
                roles=[r.name for r in u.roles],
            )
        )

    return AdminUsersPage(total=total, limit=limit, offset=offset, items=items)

# ===========================
# ✅ NEW: Admin - Delete user
# ===========================
@router.delete("/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def admin_delete_user(
    user_id: uuid.UUID = Path(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin_user),
):
    u = db.get(User, user_id)
    if not u:
        raise HTTPException(status_code=404, detail="User not found")
    db.delete(u)  # หรือ soft delete: u.is_active = False; db.add(u)
    db.commit()
    return None

# ===========================
# ✅ NEW: Admin - System summary report
# ===========================
@router.get("/reports/summary", response_model=SystemSummaryReport)
async def admin_system_summary(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin_user),
    start: Optional[datetime] = Query(None, description="ISO datetime start for attendance range"),
    end: Optional[datetime] = Query(None, description="ISO datetime end for attendance range"),
):
    total_users = db.query(func.count(User.user_id)).scalar() or 0
    total_admins = (
        db.query(func.count(User.user_id))
        .join(User.roles)
        .filter(func.lower(Role.name) == "admin")
        .scalar() or 0
    )
    total_teachers = (
        db.query(func.count(User.user_id))
        .join(User.roles)
        .filter(func.lower(Role.name) == "teacher")
        .scalar() or 0
    )
    total_students = (
        db.query(func.count(User.user_id))
        .join(User.roles)
        .filter(func.lower(Role.name) == "student")
        .scalar() or 0
    )

    total_classes = db.query(func.count(ClassModel.class_id)).scalar() or 0
    total_attendances = db.query(func.count(Attendance.attendance_id)).scalar() or 0

    q_att = db.query(func.count(Attendance.attendance_id))
    if start:
        q_att = q_att.filter(Attendance.timestamp >= start)
    if end:
        q_att = q_att.filter(Attendance.timestamp <= end)
    total_attendances_in_range = q_att.scalar() or 0

    return SystemSummaryReport(
        total_users=total_users,
        total_admins=total_admins,
        total_teachers=total_teachers,
        total_students=total_students,
        total_classes=total_classes,
        total_attendances=total_attendances,
        total_attendances_in_range=total_attendances_in_range,
        range_start=start,
        range_end=end,
    )

# ===========================
# ✅ NEW: Admin - List all classes (search + pagination)
# ===========================
@router.get("/classes", response_model=AdminClassesPage)
async def admin_list_classes(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin_user),
    q: Optional[str] = Query(None, description="search by class name/code"),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
):
    base = db.query(ClassModel)
    if q:
        like = f"%{q.strip()}%"
        filters = [ClassModel.name.ilike(like)]
        # ถ้ามีฟิลด์ code ให้ค้นหาด้วย
        if hasattr(ClassModel, "code"):
            filters.append(getattr(ClassModel, "code").ilike(like))
        base = base.filter(or_(*filters))

    total = base.count()
    rows = (
        base.order_by(getattr(ClassModel, "created_at", ClassModel.name).desc())
        .limit(limit)
        .offset(offset)
        .all()
    )

    # นับนักเรียนต่อคลาสด้วย association table
    class_ids = [r.class_id for r in rows]
    counts_map = {cid: 0 for cid in class_ids}
    if class_ids:
        count_rows = (
            db.query(class_students.c.class_id, func.count(class_students.c.student_id))
            .filter(class_students.c.class_id.in_(class_ids))
            .group_by(class_students.c.class_id)
            .all()
        )
        for cid, cnt in count_rows:
            counts_map[cid] = int(cnt)

    items: List[AdminClassSummary] = []
    for c in rows:
        teacher = db.query(User).filter(User.user_id == getattr(c, "teacher_id", None)).first()
        items.append(
            AdminClassSummary(
                class_id=c.class_id,
                name=c.name,
                code=getattr(c, "code", None),
                student_count=counts_map.get(c.class_id, 0),
                created_at=getattr(c, "created_at", datetime.utcnow()),
                teacher=UserResponse(
                    user_id=teacher.user_id,
                    username=teacher.username,
                    first_name=teacher.first_name,
                    last_name=teacher.last_name,
                    email=teacher.email,
                    is_active=teacher.is_active,
                    is_approved=getattr(teacher, "is_approved", None),
                    created_at=teacher.created_at,
                    updated_at=teacher.updated_at,
                    last_login_at=teacher.last_login_at,
                    roles=[r.name for r in teacher.roles],
                ) if teacher else None,
            )
        )

    return AdminClassesPage(
        total=total,
        limit=limit,
        offset=offset,
        items=items,
    )