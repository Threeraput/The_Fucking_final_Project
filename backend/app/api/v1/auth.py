# backend/app/api/v1/auth.py
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import datetime, timezone , timedelta
from app.core.config import settings
from app.database import get_db
from app.schemas.user_schema import UserCreate,  UserResponse, Token
from app.models.user import User
from app.services.db_service import get_user_by_email, get_user_by_username
from app.core.security import get_password_hash, verify_password, create_access_token

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register_user(user_create: UserCreate, db: Session = Depends(get_db)):
    """
    ลงทะเบียนผู้ใช้ใหม่ในระบบ
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
        # --- เปลี่ยนตรงนี้ ---
        first_name=user_create.first_name, # ใช้ first_name แทน
        last_name=user_create.last_name,   # ใช้ last_name แทน
        # ------------------
        email=user_create.email,
        student_id=user_create.student_id,
        teacher_id=user_create.teacher_id,
        is_active=True
    )

    try:
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        return new_user
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
                headers={"WWW-Authenticate": "Bearer"},
            )

    if not verify_password(form_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user_roles = [role.name for role in user.roles] # ดึง role names

    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"user_id": str(user.user_id), "roles": user_roles},
        expires_delta=access_token_expires
    )

    user.last_login_at = datetime.now(timezone.utc)
    db.add(user)
    db.commit()
    db.refresh(user)

     # สร้าง UserResponse instance แยกต่างหาก แล้วส่ง user_roles ที่เป็น list ของ string เข้าไป
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
        roles=user_roles # <--- ใช้ user_roles ที่เป็น List[str] ที่นี่
    )

    return Token(access_token=access_token, token_type="bearer", user=user_response_data)
