# backend/app/services/face_recognition_service.py
from typing import List
import face_recognition
import numpy as np
import io

def get_face_encoding(image_file: bytes) -> np.ndarray:
    """
    รับไฟล์รูปภาพ (bytes) และคืนค่า Facial Embedding (numpy array).
    """
    # โหลดรูปภาพจาก bytes
    image = face_recognition.load_image_file(io.BytesIO(image_file))
    
    # ค้นหาใบหน้าทั้งหมดในรูปภาพ
    face_locations = face_recognition.face_locations(image)
    if not face_locations:
        return None  # ไม่พบใบหน้า
    
    # ดึง Facial Embeddings
    face_encodings = face_recognition.face_encodings(image, face_locations)
    if not face_encodings:
        return None
    
    # ส่งคืน Facial Embedding ตัวแรกที่พบ
    return face_encodings[0]

def verify_face(known_face_encodings: List[np.ndarray], face_to_check: np.ndarray) -> bool:
    """
    เปรียบเทียบ Facial Embeddings เพื่อยืนยันใบหน้า
    """
    # เปรียบเทียบใบหน้ากับ Facial Embeddings ที่รู้จัก
    matches = face_recognition.compare_faces(known_face_encodings, face_to_check)
    return True in matches