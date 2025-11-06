# backend/app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from contextlib import asynccontextmanager # สำหรับ lifespan events
from app.database import engine, Base, get_db
from app.api.v1 import auth, users , admin , face_recognition ,  classes , attendance , sessions # Import เฉพาะ routers ที่สร้างแล้ว
# from app.api.v1 import classes, attendance, admin # ถ้ายังไม่มีไฟล์เหล่านี้ ให้ comment ไว้ก่อน
from app.services.db_service import initialize_roles_permissions
from fastapi.staticfiles import StaticFiles
from app.api.v1 import announcements as announcements_router
from app.api.v1 import classwork_simple
from app.api.v1 import attendance_report
from app.api.v1 import attendance_report_detail
from pathlib import Path
# ใช้ asynccontextmanager สำหรับ startup/shutdown events (ดีกว่า @app.on_event)


MEDIA_ROOT = Path("media")
MEDIA_ROOT.mkdir(parents=True, exist_ok=True)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup event
    print("Application startup: Creating database tables and initializing roles/permissions...")
    db_session = next(get_db()) # รับ db session
    try:
        Base.metadata.create_all(bind=engine) # สร้างตารางทั้งหมด (ถ้ายังไม่มี)
        initialize_roles_permissions(db_session) # สร้าง roles และ permissions เริ่มต้น
    finally:
        db_session.close() # ปิด session
    yield
    # Shutdown event (ถ้ามีอะไรต้อง cleanup)
    print("Application shutdown.")

app = FastAPI(title="Face Attendance API", version="1.0.0", lifespan=lifespan)

# ตั้งค่า CORS (Cross-Origin Resource Sharing)
origins = [
    "http://localhost",
    "http://localhost:8000", # ตัวอย่างพอร์ตที่ Flutter Web อาจรัน
    "http://127.0.0.1",
    "http://127.0.0.1:5000", # ถ้า Flutter Web รันที่พอร์ตเดียวกันกับ Backend
    "http://127.0.0.1:5500", # พอร์ตที่ VS Code Live Server หรือ Flutter Web อาจใช้
    "http://192.168.1.141:5000", # IP Address ของเครื่องที่รัน Backend
    "file://", 
    "null", 
    # เพิ่ม IP Address ของเครื่องที่คุณรัน Flutter App หากทดสอบบนมือถือจริงในเครือข่ายเดียวกัน
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# รวม API Routers
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")
app.mount("/workpdf", StaticFiles(directory="workpdf"), name="workpdf")
app.mount("/media", StaticFiles(directory=str(MEDIA_ROOT)), name="media")
app.include_router(auth.router, prefix="/api/v1")
app.include_router(users.router, prefix="/api/v1")
app.include_router(face_recognition.router, prefix="/api/v1")
# ถ้าคุณยังไม่ได้สร้าง routers อื่นๆ ให้ comment บรรทัดเหล่านี้ไว้ก่อน เพื่อป้องกัน ImportError
app.include_router(classes.router, prefix="/api/v1")
app.include_router(attendance.router, prefix="/api/v1")
app.include_router(admin.router, prefix="/api/v1")
app.include_router(sessions.router, prefix="/api/v1")
app.include_router(classwork_simple.router, prefix="/api/v1")
app.include_router(announcements_router.router, prefix="/api/v1")
app.include_router(attendance_report.router , prefix="/api/v1")
app.include_router(attendance_report_detail.router, prefix="/api/v1")

# --- Optional: Default root endpoint ---
@app.get("/")
async def read_root():
    return {"message": "Welcome to the Face Attendance API!"}