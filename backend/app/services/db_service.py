# backend/app/services/db_service.py

from sqlalchemy.orm import Session
from app.models.user import User
from app.models.role import Role
from app.models.permission import Permission
import uuid # เพิ่ม import นี้

def get_user_by_username(db: Session, username: str):
    """ดึงข้อมูลผู้ใช้จาก username"""
    return db.query(User).filter(User.username == username).first()

def get_user_by_email(db: Session, email: str):
    """ดึงข้อมูลผู้ใช้จาก email"""
    return db.query(User).filter(User.email == email).first()

def get_user_by_id(db: Session, user_id: uuid.UUID):
    """ดึงข้อมูลผู้ใช้จาก user_id"""
    return db.query(User).filter(User.user_id == user_id).first()

def initialize_roles_permissions(db: Session):
    """
    สร้าง Roles และ Permissions เริ่มต้นถ้ายังไม่มีในฐานข้อมูล
    """
    print("Initializing roles and permissions...")
    # ตรวจสอบและสร้าง Role 'admin'
    admin_role = db.query(Role).filter(Role.name == "admin").first()
    if not admin_role:
        admin_role = Role(name="admin", description="Administrator role with full access")
        db.add(admin_role)

    # ตรวจสอบและสร้าง Role 'teacher'
    teacher_role = db.query(Role).filter(Role.name == "teacher").first()
    if not teacher_role:
        teacher_role = Role(name="teacher", description="Teacher role with class management permissions")
        db.add(teacher_role)

    # ตรวจสอบและสร้าง Role 'student'
    student_role = db.query(Role).filter(Role.name == "student").first()
    if not student_role:
        student_role = Role(name="student", description="Student role with attendance viewing permissions")
        db.add(student_role)

    # ตัวอย่าง permissions
    view_users_perm = db.query(Permission).filter(Permission.name == "view_users").first()
    if not view_users_perm:
        view_users_perm = Permission(name="view_users", description="Can view all user details")
        db.add(view_users_perm)

    manage_classes_perm = db.query(Permission).filter(Permission.name == "manage_classes").first()
    if not manage_classes_perm:
        manage_classes_perm = Permission(name="manage_classes", description="Can create, update, delete classes")
        db.add(manage_classes_perm)

    try:
        db.commit() # Commit changes to save new roles/permissions
        # db.refresh(admin_role) # refresh objects after commit to ensure relationships are loaded
        # db.refresh(teacher_role)
        # db.refresh(student_role)
        # db.refresh(view_users_perm)
        # db.refresh(manage_classes_perm)
        print("Roles and Permissions added/checked.")
    except Exception as e:
        db.rollback()
        print(f"Error during initial role/permission creation commit: {e}")

    # กำหนดความสัมพันธ์ระหว่าง Role และ Permission (ถ้ายังไม่มี)
    if admin_role and view_users_perm and manage_classes_perm:
        # โหลด relationship collections ก่อนใช้งานเพื่อหลีกเลี่ยง DetachedInstanceError
        if view_users_perm not in admin_role.permissions:
            admin_role.permissions.append(view_users_perm)
        if manage_classes_perm not in admin_role.permissions:
            admin_role.permissions.append(manage_classes_perm)

    if teacher_role and manage_classes_perm:
        if manage_classes_perm not in teacher_role.permissions:
            teacher_role.permissions.append(manage_classes_perm)

    try:
        db.commit()
        print("Role-Permission relationships assigned.")
    except Exception as e:
        db.rollback()
        print(f"Error during role-permission assignment commit: {e}")