# backend/app/api/v1/users.py

from fastapi import APIRouter, Depends, HTTPException, status, Path # เพิ่ม Path
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime, timezone # ต้องมี datetime และ timezone
import uuid # ต้องมี uuid

from app.database import get_db
from app.schemas.user_schema import UserResponse, TokenData, UserUpdate # ตรวจสอบว่ามี UserUpdate
from app.models.user import User
from app.services.db_service import get_user_by_id
from app.core.security import decode_access_token

# กำหนด scheme สำหรับ OAuth2
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/auth/token")

async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> User:
    # ... (โค้ดสำหรับ get_current_user คงเดิม) ...
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    token_data = decode_access_token(token)
    if token_data is None:
        raise credentials_exception

    user = get_user_by_id(db, user_id=token_data.user_id)
    if user is None:
        raise credentials_exception
    return user


async def get_current_active_user(current_user: User = Depends(get_current_user)) -> User:
    # ... (โค้ดสำหรับ get_current_active_user คงเดิม) ...
    if not current_user.is_active:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Inactive user")
    return current_user

# Dependency สำหรับการตรวจสอบสิทธิ์ Admin (สำคัญสำหรับ GET all, GET by ID, PUT, DELETE)
async def get_current_admin_user(current_user: User = Depends(get_current_active_user)) -> User:
    """
    Dependency เพื่อยืนยันว่าผู้ใช้ปัจจุบันเป็น Admin
    """
    if "admin" not in [role.name for role in current_user.roles]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions. Admin required."
        )
    return current_user

router = APIRouter(prefix="/users", tags=["Users"]) # ตั้งชื่อตัวแปรเป็น router

@router.get("/me", response_model=UserResponse)
async def read_users_me(current_user: User = Depends(get_current_active_user)):
    # ... (โค้ดสำหรับ read_users_me คงเดิม) ...
    _ = current_user.roles
    user_roles = [role.name for role in current_user.roles]
    user_response_data = UserResponse(
        user_id=current_user.user_id,
        username=current_user.username,
        first_name=current_user.first_name,
        last_name=current_user.last_name,
        email=current_user.email,
        is_active=current_user.is_active,
        created_at=current_user.created_at,
        updated_at=current_user.updated_at,
        last_login_at=current_user.last_login_at,
        roles=user_roles
    )
    return user_response_data

@router.get("/{user_id}", response_model=UserResponse)
async def read_user_by_id(
    user_id: uuid.UUID = Path(..., description="The UUID of the user to retrieve"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin_user) # เฉพาะ Admin เท่านั้นที่ดึงข้อมูลผู้ใช้คนอื่นได้
):
    # ... (โค้ดสำหรับ read_user_by_id คงเดิม) ...
    user = get_user_by_id(db, user_id=user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    _ = user.roles
    user_roles = [role.name for role in user.roles]
    user_response_data = UserResponse(
        user_id=user.user_id,
        username=user.username,
        first_name=user.first_name,
        last_name=user.last_name,
        email=user.email,
        is_active=user.is_active,
        created_at=user.created_at,
        updated_at=user.updated_at,
        last_login_at=user.last_login_at,
        roles=user_roles
    )
    return user_response_data


@router.get("/", response_model=List[UserResponse])
async def read_all_users(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin_user) # เฉพาะ Admin เท่านั้นที่ดึงข้อมูลผู้ใช้ทั้งหมดได้
):
    # ... (โค้ดสำหรับ read_all_users คงเดิม) ...
    users = db.query(User).all()
    response_users = []
    for user in users:
        _ = user.roles
        user_roles = [role.name for role in user.roles]
        user_response_data = UserResponse(
            user_id=user.user_id,
            username=user.username,
            first_name=user.first_name,
            last_name=user.last_name,
            email=user.email,
            is_active=user.is_active,
            created_at=user.created_at,
            updated_at=user.updated_at,
            last_login_at=user.last_login_at,
            roles=user_roles
        )
        response_users.append(user_response_data)
    return response_users

@router.put("/{user_id}", response_model=UserResponse)
async def update_user(
    user_update: UserUpdate, # ใช้ UserUpdate schema
    user_id: uuid.UUID = Path(..., description="The UUID of the user to update"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    # ... (โค้ดสำหรับ update_user คงเดิม) ...
    # ตรวจสอบสิทธิ์: ผู้ใช้จะอัปเดตได้เฉพาะโปรไฟล์ตัวเอง หรือ Admin เท่านั้น
    if str(current_user.user_id) != str(user_id) and "admin" not in [role.name for role in current_user.roles]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to update this user's profile"
        )

    db_user = get_user_by_id(db, user_id=user_id)
    if not db_user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    # อัปเดตฟิลด์ต่างๆ ตามที่รับมาใน user_update
    if user_update.username is not None:
        db_user.username = user_update.username
    if user_update.first_name is not None:
        db_user.first_name = user_update.first_name
    if user_update.last_name is not None:
        db_user.last_name = user_update.last_name
    if user_update.email is not None:
        db_user.email = user_update.email
    if user_update.student_id is not None:
        db_user.student_id = user_update.student_id
    if user_update.teacher_id is not None:
        db_user.teacher_id = user_update.teacher_id
    if user_update.is_active is not None:
        db_user.is_active = user_update.is_active

    db_user.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(db_user)

    user_roles = [role.name for role in db_user.roles]
    user_response_data = UserResponse(
        user_id=db_user.user_id,
        username=db_user.username,
        first_name=db_user.first_name,
        last_name=db_user.last_name,
        email=db_user.email,
        is_active=db_user.is_active,
        created_at=db_user.created_at,
        updated_at=db_user.updated_at,
        last_login_at=db_user.last_login_at,
        roles=user_roles
    )
    return user_response_data


@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(
    user_id: uuid.UUID = Path(..., description="The UUID of the user to delete"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin_user) # เฉพาะ Admin เท่านั้นที่ลบผู้ใช้ได้
):
    # ... (โค้ดสำหรับ delete_user คงเดิม) ...
    db_user = get_user_by_id(db, user_id=user_id)
    if not db_user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    if str(db_user.user_id) == str(current_user.user_id):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Cannot delete your own user account via this endpoint.")

    db.delete(db_user)
    db.commit()
    return {"message": "User deleted successfully."}