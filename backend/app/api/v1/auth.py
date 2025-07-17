# backend/app/api/v1/auth.py
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import datetime, timezone, timedelta
import uuid # ตรวจสอบให้แน่ใจว่ามีการนำเข้า uuid
from typing import Optional # เพิ่มการนำเข้า Optional

from app.core.config import settings
from app.database import get_db
from app.schemas.user_schema import (
    UserCreate,
    UserLogin, # มีอยู่แล้ว
    UserResponse, # มีอยู่แล้ว
    Token, # มีอยู่แล้ว
)
from app.schemas.otp_schema import (
    OTPRequest,
    OTPVerification,
    PasswordResetRequest
)
from app.models.user import User
from app.services.db_service import get_user_by_email, get_user_by_username
from app.core.security import get_password_hash, verify_password, create_access_token

# นำเข้า Service ใหม่สำหรับ OTP และ Email
from app.services.otp_service import create_otp, verify_otp, get_user_by_email_or_username_for_otp # <-- ต้องสร้างไฟล์นี้และฟังก์ชันเหล่านี้
from app.services.email_service import send_email # <-- ต้องสร้างไฟล์นี้และฟังก์ชันนี้

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register_user(user_create: UserCreate, db: Session = Depends(get_db)):
    """
    ลงทะเบียนผู้ใช้ใหม่ในระบบ และส่ง OTP เพื่อยืนยันอีเมล
    """
    db_user_by_username = get_user_by_username(db, username=user_create.username)
    if db_user_by_username:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Username already registered")

    if user_create.email:
        db_user_by_email = get_user_by_email(db, email=user_create.email)
        if db_user_by_email:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already registered")

    hashed_password = get_password_hash(user_create.password)

    new_user = User(
        username=user_create.username,
        password_hash=hashed_password,
        first_name=user_create.first_name,
        last_name=user_create.last_name,
        email=user_create.email,
        student_id=user_create.student_id,
        teacher_id=user_create.teacher_id,
        is_active=False # <--- เปลี่ยนตรงนี้: ผู้ใช้ใหม่จะไม่ Active จนกว่าจะยืนยัน OTP
    )

    try:
        db.add(new_user)
        db.commit()
        db.refresh(new_user)

        # สร้าง OTP และส่งอีเมล
        otp_record = create_otp(db, new_user.user_id)
        otp_sent = await send_email(
            recipients=[new_user.email],
            subject="ยืนยันอีเมลสำหรับบัญชีของคุณ",
            body=f"รหัส OTP ของคุณคือ: {otp_record.otp_code}\nรหัสนี้จะหมดอายุภายใน {settings.OTP_EXPIRE_MINUTES} นาที"
        )
        if not otp_sent:
            # ถ้าส่งอีเมลไม่สำเร็จ อาจจะลบผู้ใช้ที่เพิ่งสร้าง หรือทำเครื่องหมายว่ายังไม่สมบูรณ์
            db.rollback() # หรืออาจจะแค่บันทึก log แล้วปล่อยให้ผู้ใช้ request OTP ใหม่
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to send OTP email. Please try again or contact support."
            )

        return new_user # ส่ง UserResponse กลับไป โดยที่ is_active เป็น False

    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Failed to register user: {e}")

# login_for_access_token (คงเดิม)
@router.post("/token", response_model=Token)
async def login_for_access_token(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    # ... โค้ดส่วนนี้คงเดิม ...
    user = get_user_by_email(db, email=form_data.username) # ใช้ form_data.username เป็น email
    if not user:
        # ถ้าไม่พบด้วย email ลองหาด้วย username
        user = get_user_by_username(db, username=form_data.username)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect email or username",
                headers={"WWW-Authenticate": "Bearer"},\
            )

    # เพิ่มการตรวจสอบ is_active ก่อนอนุญาตให้ login
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account not activated. Please verify your email with OTP."
        )

    if not verify_password(form_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user_roles = [role.name for role in user.roles]

    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"user_id": str(user.user_id), "roles": user_roles},
        expires_delta=access_token_expires
    )

    user.last_login_at = datetime.now(timezone.utc)
    db.add(user)
    db.commit()
    db.refresh(user)

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

    return Token(access_token=access_token, token_type="bearer", user=user_response_data)

# --- Endpoint ใหม่สำหรับ OTP และ Password Reset ---

@router.post("/request-otp", status_code=status.HTTP_200_OK)
async def request_otp_for_action(otp_request: OTPRequest, db: Session = Depends(get_db)):
    """
    ขอ OTP สำหรับการยืนยันตัวตน (เช่น การ Activate บัญชี หรือรีเซ็ตรหัสผ่าน)
    """
    user = get_user_by_email_or_username_for_otp(db, email_or_username=otp_request.email)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found.")

    otp_record = create_otp(db, user.user_id)
    otp_sent = await send_email(
        recipients=[user.email],
        subject="รหัส OTP ของคุณ",
        body=f"รหัส OTP ของคุณคือ: {otp_record.otp_code}\nรหัสนี้จะหมดอายุภายใน {settings.OTP_EXPIRE_MINUTES} นาที"
    )
    if not otp_sent:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to send OTP email.")

    return {"message": "OTP sent successfully to your email."}

@router.post("/verify-otp", status_code=status.HTTP_200_OK)
async def verify_otp_and_activate_account(otp_verification: OTPVerification, db: Session = Depends(get_db)):
    """
    ตรวจสอบ OTP และ Activate บัญชีผู้ใช้
    """
    user = get_user_by_email_or_username_for_otp(db, email_or_username=otp_verification.email)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found.")

    is_valid_otp = verify_otp(db, user.user_id, otp_verification.otp_code)
    if not is_valid_otp:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid or expired OTP.")

    if user.is_active:
        return {"message": "Account is already active."} # กรณีผู้ใช้ active แล้ว แต่ก็ส่ง OTP มาอีก

    user.is_active = True
    user.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(user)

    return {"message": "Account activated successfully."}

@router.post("/reset-password", status_code=status.HTTP_200_OK)
async def reset_password_with_otp(reset_request: PasswordResetRequest, db: Session = Depends(get_db)):
    """
    รีเซ็ตรหัสผ่านของผู้ใช้หลังจากยืนยัน OTP แล้ว
    """
    user = get_user_by_email_or_username_for_otp(db, email_or_username=reset_request.email)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found.")

    is_valid_otp = verify_otp(db, user.user_id, reset_request.otp_code)
    if not is_valid_otp:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid or expired OTP.")

    # ตรวจสอบว่ารหัสผ่านใหม่ไม่ว่างเปล่า
    if not reset_request.new_password:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="New password cannot be empty.")

    user.password_hash = get_password_hash(reset_request.new_password)
    user.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(user)

    return {"message": "Password has been reset successfully."}