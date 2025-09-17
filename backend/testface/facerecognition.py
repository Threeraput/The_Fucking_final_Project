from PIL import Image
import os
import cv2
import face_recognition
import numpy as np
from PIL import Image



# The program we will be finding faces on the example below
BASE_DIR = os.path.dirname(__file__)

img_path1 = os.path.join(BASE_DIR, "obama.jpg")
pil_im = Image.open(img_path1)


# Load a sample picture and learn how to recognize it.
obama_image = face_recognition.load_image_file(img_path1)
obama_face_encoding = face_recognition.face_encodings(obama_image)[0]

# Load a second sample picture and learn how to recognize it.
img_path2 = os.path.join(BASE_DIR, "biden.jpg")
biden_image = face_recognition.load_image_file(img_path2)
biden_face_encoding = face_recognition.face_encodings(biden_image)[0]

# Load a second sample picture and learn how to recognize it.
img_path3 = os.path.join(BASE_DIR, "soodlor.jpg")
soodlor_image = face_recognition.load_image_file(img_path3)
soodlor_face_encoding = face_recognition.face_encodings(soodlor_image)[0]

# Load a second sample picture and learn how to recognize it.
img_path4 = os.path.join(BASE_DIR, "guykak.jpg")
guykak_image = face_recognition.load_image_file(img_path4)
guykak_face_encoding = face_recognition.face_encodings(guykak_image)[0]

# Load a second sample picture and learn how to recognize it.
img_path5 = os.path.join(BASE_DIR, "pek.png")
pek_image = face_recognition.load_image_file(img_path5)
pek_face_encoding = face_recognition.face_encodings(pek_image)[0]

# Load a second sample picture and learn how to recognize it.
img_path6 = os.path.join(BASE_DIR, "ford.jpg")
ford_image = face_recognition.load_image_file(img_path6)
ford_face_encoding = face_recognition.face_encodings(ford_image)[0]

# Create arrays of known face encodings and their names
known_face_encodings = [
    obama_face_encoding,
    biden_face_encoding,
    soodlor_face_encoding,
    guykak_face_encoding,
    pek_face_encoding,
    ford_face_encoding
]
known_face_names = [
    "Barack Obama",
    "Joe Biden",
    "Ipor Soodlor",
    "Guy Kak",
    "Pek Ngo",
    "kuy ford"
]
print('Learned encoding for', len(known_face_encodings), 'images.')

# โหลดรูปภาพที่รู้จักและสร้าง Face Encoding
known_face_encodings = []
known_face_names = []

# รายการไฟล์รูปภาพและชื่อที่เกี่ยวข้อง
image_files = [
    (img_path1, "Barack Obama"),
    (img_path2, "Joe Biden"),
    (img_path3, "Ipor Soodlor"),
    (img_path4, "Guy Kak"),
    (img_path5, "Pek Ngo"),
    (img_path6, "Kuy Ford")
]

# โหลดและสร้าง Face Encoding
for file , name in image_files:
    image = face_recognition.load_image_file(file)
    encodings = face_recognition.face_encodings(image)
    if encodings:  # ตรวจสอบว่ามีใบหน้าในภาพหรือไม่
        known_face_encodings.append(encodings[0])
        known_face_names.append(name)

print(f'เรียนรู้ {len(known_face_encodings)} คน จากฐานข้อมูลรูปภาพ')

# เปิดใช้งานเว็บแคม
video_capture = cv2.VideoCapture(0)

while True:
    ret, frame = video_capture.read()
    if not ret:
        print("ไม่สามารถอ่านภาพจากเว็บแคมได้")
        break

    # แปลงภาพจาก BGR (OpenCV) เป็น RGB (face_recognition ใช้ RGB)
    rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

    # ตรวจจับตำแหน่งใบหน้า
    face_locations = face_recognition.face_locations(rgb_frame, model="hog")

    # เข้ารหัสใบหน้าที่ตรวจพบ
    face_encodings = face_recognition.face_encodings(rgb_frame, face_locations)

    # วนลูปใบหน้าทั้งหมดที่พบ
    for (top, right, bottom, left), face_encoding in zip(face_locations, face_encodings):
        # เปรียบเทียบใบหน้ากับฐานข้อมูล
        matches = face_recognition.compare_faces(known_face_encodings, face_encoding, tolerance=0.45)
        name = "Unknown"

        # คำนวณความใกล้เคียงของใบหน้าที่พบ
        face_distances = face_recognition.face_distance(known_face_encodings, face_encoding)
        best_match_index = np.argmin(face_distances)

        if matches[best_match_index]:
            name = known_face_names[best_match_index]

        # วาดกรอบรอบใบหน้า
        cv2.rectangle(frame, (left, top), (right, bottom), (0, 0, 255), 2)

        # วาดป้ายชื่อด้านล่าง
        cv2.rectangle(frame, (left, bottom - 35), (right, bottom), (0, 0, 255), cv2.FILLED)
        font = cv2.FONT_HERSHEY_DUPLEX
        cv2.putText(frame, name, (left + 6, bottom - 6), font, 0.8, (255, 255, 255), 1)

    # แสดงผลลัพธ์จากเว็บแคม
    cv2.imshow('Real-time Face Recognition', frame)

    # กด 'q' เพื่อออกจากโปรแกรม
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

# ปิดการใช้งานเว็บแคม
video_capture.release()
cv2.destroyAllWindows()