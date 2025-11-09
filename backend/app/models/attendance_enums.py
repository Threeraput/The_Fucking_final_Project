from enum import Enum as PyEnum

class AttendanceStatus(str, PyEnum):
    """กำหนดสถานะการเข้าเรียน (ค่าที่เก็บใน DB ควรตรงกับค่าที่นี่)"""
    PRESENT = "present"
    LATE = "late"
    ABSENT = "absent"
    LEFT_EARLY = "left_early"       # ตรวจพบว่าเดินออกจากพื้นที่หลังเช็คอิน
    UNVERIFIED_FACE = "unverified_face" # Face Scan ไม่ผ่าน
    MANUAL_OVERRIDE = "manual_override" # ถูกแก้ไขโดยอาจารย์/แอดมิน
