# backend/app/api/v1/admin.py
from fastapi import APIRouter, Depends, HTTPException, status, Path
from typing import List
from sqlalchemy.orm import Session
import uuid
from app.database import get_db
from app.schemas.user_schema import UserResponse # ใช้สำหรับ Response
from app.models.user import User # ใช้ User Model
from app.services.db_service import approve_teacher # ฟังก์ชัน Approve
from app.core.deps import get_current_admin_user # Dependency สำหรับ Admin

router = APIRouter(prefix="/admin", tags=["Admin"]) # ตั้งชื่อตัวแปรเป็น router

@router.get("/status", response_model=dict)
async def get_admin_status(current_user: User = Depends(get_current_admin_user)):
    """
    A simple test endpoint for admin status. Requires Admin role.
    """
    return {"message": f"Admin endpoint is working! Welcome, {current_user.username}."}

# endpoint for approving a teacher

@router.post("/users/{user_id}/approve-teacher", response_model=UserResponse)
async def approve_user_as_teacher(
    user_id: uuid.UUID = Path(..., description="The UUID of the teacher user to approve"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin_user) # เฉพาะ Admin เท่านั้น
):
    """
    Approves a teacher account. Requires Admin role.
    The user must already have the 'teacher' role assigned.
    """
    approved_user = approve_teacher(db, user_id)
    if not approved_user:
        raise HTTPException(status_code=status.HTTP_404_NOT_CODE, detail="User not found or is not a teacher.")

    # Ensure roles are loaded before responding
    _ = approved_user.roles
    return approved_user

@router.get("/pending-teachers", response_model=List[UserResponse])
async def get_pending_teachers(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin_user)
):
    """
    ดึงรายชื่อ Teacher ที่ยังไม่ได้รับการอนุมัติ (สำหรับ Admin).
    """
    pending_teachers = db.query(User).filter(
        User.is_approved == False
    ).all()
    
    # --- แก้ไขตรงนี้: สร้าง List ของ UserResponse ที่มี roles เป็น String ---
    response_list = []
    for user in pending_teachers:
        # ดึง roles สำหรับแต่ละ user ก่อน return
        user_roles = [role.name for role in user.roles]
        
        user_response = UserResponse(
            user_id=user.user_id,
            username=user.username,
            first_name=user.first_name,
            last_name=user.last_name,
            email=user.email,
            is_active=user.is_active,
            is_approved=user.is_approved,
            created_at=user.created_at,
            updated_at=user.updated_at,
            last_login_at=user.last_login_at,
            roles=user_roles # <-- ส่ง roles ที่เป็น string
        )
        response_list.append(user_response)
    
    return response_list