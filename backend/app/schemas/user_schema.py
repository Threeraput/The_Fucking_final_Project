# backend/app/schemas/user_schema.py
import uuid
from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
from datetime import datetime

# --- Schemas สำหรับ User หลัก ---

class UserBase(BaseModel):
    username: str = Field(..., min_length=3, max_length=80)
    first_name: str = Field(..., min_length=1, max_length=60)
    last_name: str = Field(..., min_length=1, max_length=60) 
    email: EmailStr = Field(..., max_length=120)

class UserCreate(UserBase):
    password: str = Field(..., min_length=6)
    student_id: Optional[str] = Field(None, max_length=20)
    teacher_id: Optional[str] = Field(None, max_length=20)
    role: str = Field(..., pattern="^(student|teacher|admin)$")

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserUpdate(BaseModel):
    username: Optional[str] = Field(None, min_length=3, max_length=80)
    first_name: Optional[str] = Field(None, min_length=1, max_length=60) 
    last_name: Optional[str] = Field(None, min_length=1, max_length=60) 
    email: Optional[EmailStr] = Field(None, max_length=120)
    student_id: Optional[str] = Field(None, max_length=20)
    teacher_id: Optional[str] = Field(None, max_length=20)
    is_active: Optional[bool] = None

class UserResponse(UserBase):
    user_id: uuid.UUID
    is_active: bool
    is_approved: Optional[bool] = None
    created_at: datetime
    updated_at: datetime
    last_login_at: Optional[datetime] = None
    roles: List[str] = [] # To include role names in response

class Config:
    from_attributes = True # สำหรับ Pydantic v2

# --- Schemas สำหรับ Token / Authentication ---

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse # Include user details in token response

class TokenData(BaseModel):
    user_id: uuid.UUID
    roles: List[str]