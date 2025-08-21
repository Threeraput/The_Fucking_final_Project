# backend/app/services/db_service.py
import uuid
import random
import string
from typing import Optional, List
from sqlalchemy import select, and_
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from datetime import datetime, timezone

from app.models.user import User
from app.models.role import Role
from app.models.permission import Permission
from app.models.association import user_roles, role_permissions # <-- นำเข้า Table Objects

# --- CRUD Read Operations for User ---
def get_user_by_username(db: Session, username: str) -> Optional[User]:
    """Retrieves a user by their username."""
    return db.query(User).filter(User.username == username).first()

def get_user_by_email(db: Session, email: str) -> Optional[User]:
    """Retrieves a user by their email."""
    return db.query(User).filter(User.email == email).first()

def get_user_by_id(db: Session, user_id: uuid.UUID) -> Optional[User]:
    """Retrieves a user by their user ID."""
    return db.query(User).filter(User.user_id == user_id).first()

# --- Functions to Generate IDs ---
def generate_student_id() -> str:
    """Generates a unique student ID (e.g., STU-UUID_PART)."""
    return f"STU-{uuid.uuid4().hex[:8].upper()}"

def generate_teacher_id() -> str:
    """Generates a unique teacher ID (e.g., TEA-UUID_PART)."""
    return f"TEA-{uuid.uuid4().hex[:8].upper()}"

# --- CRUD Operations and Business Logic ---
def assign_role_to_user(db: Session, user: User, role_name: str):
    """Assigns a role to a user if not already assigned."""
    role = db.query(Role).filter(Role.name == role_name).first()
    if not role:
        raise ValueError(f"Role '{role_name}' not found.")

    # ตรวจสอบว่าผู้ใช้มี role นี้แล้วหรือไม่โดย Query จาก Table Object
    stmt = select(user_roles).where(
        and_(user_roles.c.user_id == user.user_id, user_roles.c.role_id == role.id)
    )
    existing_assignment = db.execute(stmt).first()

    if not existing_assignment:
        db.execute(user_roles.insert().values(user_id=user.user_id, role_id=role.id))

def approve_teacher(db: Session, user_id: uuid.UUID) -> Optional[User]:
    """Approves a teacher user."""
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        return None
    
    # Check if user has the 'teacher' role by querying Table Object
    stmt = select(user_roles).join(Role).where(
        and_(user_roles.c.user_id == user.user_id, Role.name == "teacher")
    )
    if not db.execute(stmt).first():
        raise ValueError("User is not a teacher.")

    user.is_approved = True
    return user

# --- Initial Database Setup Logic (for startup event) ---
def initialize_roles_permissions(db: Session):
    """
    Initializes default roles and permissions in the database.
    This function is intended to be called only once on application startup.
    """
    print("Initializing roles and permissions...")

    # Create Roles if they don't exist
    role_names = ["admin", "teacher", "student", "teaching_assistant"]
    for role_name in role_names:
        if not db.query(Role).filter(Role.name == role_name).first():
            db.add(Role(name=role_name))
    
    # Create Permissions if they don't exist
    permissions_data = [
        {"name": "manage_users", "description": "Create, edit, delete user accounts"},
        {"name": "view_all_attendance", "description": "View all attendance records across the system"},
        {"name": "edit_class_attendance", "description": "Edit attendance records for classes they are assigned to"},
        {"name": "manage_classes", "description": "Create, edit, delete classes they are assigned to"},
        {"name": "perform_self_attendance", "description": "Perform self-attendance check"},
        {"name": "approve_enrollment_requests", "description": "Approve student enrollment requests"},
        {"name": "manage_face_samples", "description": "Add/remove face samples for users"},
    ]
    for perm_data in permissions_data:
        if not db.query(Permission).filter(Permission.name == perm_data["name"]).first():
            db.add(Permission(**perm_data))

    db.commit() # Commit new roles/permissions before assigning relationships

    # Assign Permissions to Roles (after roles and permissions exist)
    role_permission_assignments = {
        'admin': ['manage_users', 'view_all_attendance', 'edit_class_attendance', 'manage_classes', 'approve_enrollment_requests', 'manage_face_samples'],
        'teacher': ['view_class_attendance', 'edit_class_attendance', 'manage_classes', 'approve_enrollment_requests', 'manage_face_samples'],
        'student': ['perform_self_attendance'],
        'teaching_assistant': ['view_class_attendance', 'approve_enrollment_requests']
    }

    for role_name, perm_names in role_permission_assignments.items():
        role = db.query(Role).filter(Role.name == role_name).first()
        if not role: continue
        
        for perm_name in perm_names:
            permission = db.query(Permission).filter(Permission.name == perm_name).first()
            if not permission: continue

            # เช็คว่า assignment มีอยู่แล้วหรือไม่โดยใช้ Table Object
            stmt = select(role_permissions).where(
                and_(role_permissions.c.role_id == role.id, role_permissions.c.permission_id == permission.id)
            )
            if not db.execute(stmt).first():
                db.execute(role_permissions.insert().values(role_id=role.id, permission_id=permission.id))
    
    db.commit() # Final commit for relationship assignments
    print("Role and permission initialization complete.")