import os
import uuid
from typing import Tuple
from fastapi import UploadFile, HTTPException
from starlette import status

# 📁 โฟลเดอร์เก็บไฟล์ PDF (เปลี่ยนจาก uploads/classwork → workpdf)
UPLOAD_DIR = os.path.join("workpdf")

# ขนาดไฟล์สูงสุด (10 MB)
MAX_SIZE_BYTES = 10 * 1024 * 1024

# สร้างโฟลเดอร์ถ้ายังไม่มี
os.makedirs(UPLOAD_DIR, exist_ok=True)

def _is_pdf_signature(data: bytes) -> bool:
    # PDF จะขึ้นต้นด้วย "%PDF"
    return data.startswith(b"%PDF")

async def save_pdf_only(file: UploadFile) -> str:
    """
    รับเฉพาะไฟล์ PDF:
    - ตรวจ MIME
    - ตรวจ signature
    - จำกัดขนาด
    - เซฟเป็นชื่อสุ่ม .pdf
    return: path แบบ relative ที่บันทึกไว้
    """
    if file.content_type not in ("application/pdf", "application/x-pdf"):
        raise HTTPException(status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
                            detail="Only PDF files are allowed")

    # อ่านบางส่วนเพื่อตรวจ signature และวัดขนาด
    first_chunk = await file.read(8 * 1024)   # 8KB แรก
    if not _is_pdf_signature(first_chunk):
        raise HTTPException(status_code=400, detail="Invalid PDF file")

    # เก็บเนื้อไฟล์ทั้งหมดพร้อมจำกัดขนาด
    chunks = [first_chunk]
    total = len(first_chunk)
    while True:
        chunk = await file.read(1024 * 1024)  # 1MB ต่อรอบ
        if not chunk:
            break
        total += len(chunk)
        if total > MAX_SIZE_BYTES:
            raise HTTPException(status_code=413, detail="PDF too large (max 10 MB)")
        chunks.append(chunk)

    # ตั้งชื่อไฟล์ปลายทาง
    filename = f"{uuid.uuid4()}.pdf"
    dest_path = os.path.join(UPLOAD_DIR, filename)

    # เขียนไฟล์ลงดิสก์
    with open(dest_path, "wb") as f:
        for c in chunks:
            f.write(c)

    # คืน path แบบ relative (เช่น workpdf/xxxx.pdf)
    return dest_path.replace("\\", "/")
