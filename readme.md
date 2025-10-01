*/
ขั้นตอนการนำไฟล์ลงเครื่้อง
1.ติดตั้ง Git
อันนี้วิธีเเบบ HTTPS
2.ใช้คำสั่ง clone ไฟล์ลงเครื่อง ตามขั้นตอนด้านล่าง 

Ex. git clone https://github.com/Threeraput/The_Fucking_final_Project.git ในcmd

อีกวิธีติดตั้งเเบบ SSH 
1.ติดตั้ง https://cli.github.com/ 
2.ใช้คำสั่ง 

Ex.gh repo clone Threeraput/The_Fucking_final_Project ในcmd
/*

1.สร้าง Visual Environment 
ทำตามขั้นตอนเว็บไซต์นี้ https://devhub.in.th/blog/python-virtual-environment-venv 
1.2 สร้าง File .env ใน Folder Backend ใส่ข้อมูลที่จำเป็นใน File .env เช่น DataBase Secretkey#

2.ติดตั้งโปรเเกรมที่จำเป็นสำหรับ lib facrecognition 
- CMake (ติดตั้งเอาไว้ข้างนอก ไม่ใช่ ติดตั้งใน .venv ภายใน)
- ติดตั้ง Visual Studio Build Tools (https://visualstudio.microsoft.com/)
    * โหลดจาก Visual Studio Build Tools 
    * ตอนติดตั้งเลือก workload: Desktop development with C++

/*
3.ติดตั้ง lib ทั้งหมดใน requirements.txt
     pip install -r requirements.txt

*/  
3.1 ลดเวอร์ชัน urllib3

ติดตั้งเวอร์ชันที่ compatible

pip install "urllib3<2" --force-reinstall
ใช้ในกรณีที่เกิด Errors pyrebase4 4.8.0 requires urllib3<2,>=1.21.1
but you have urllib3 2.5.0 which is incompatible.
/*
*/

/*
# -------------------------------
# Database (PostgreSQL)
# -------------------------------
DATABASE_URL=postgresql://postgres:yourpassword@localhost:5432/mydatabase

# -------------------------------
# FastAPI / JWT
# -------------------------------
SECRET_KEY=your_super_secret_key
ACCESS_TOKEN_EXPIRE_MINUTES=60   # token หมดอายุ 60 นาที
ALGORITHM=HS256                   # ใช้ HMAC SHA256

# -------------------------------
# AWS S3 (ถ้าใช้)
# -------------------------------
# AWS_ACCESS_KEY_ID=YOUR_AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY=YOUR_AWS_SECRET_ACCESS_KEY
# AWS_REGION=ap-southeast-1       # เช่น Bangkok
# S3_BUCKET_NAME=your-face-attendance-bucket

# -------------------------------
# Email service settings
# -------------------------------
MAIL_USERNAME=your_email@example.com
MAIL_PASSWORD=your_email_password
MAIL_FROM=your_email@example.com
MAIL_PORT=587                     # SMTP port (เช่น Gmail ใช้ 587)
MAIL_SERVER=smtp.gmail.com        # SMTP server
MAIL_STARTTLS=True                # ใช้ STARTTLS
MAIL_SSL_TLS=False                # ใช้ SSL/TLS
MAIL_USE_CREDENTIALS=True         # ใช้ username/password

# -------------------------------
# OTP settings
# -------------------------------
OTP_LENGTH=6                      # ความยาว OTP
OTP_EXPIRE_MINUTES=5              # OTP หมดอายุ 5 นาที
*/

/*
4.จะทำเรื่อง OTP เพิ่ม 
4.1 ก็ไปทำการสมัคร app passwords google --> https://support.google.com/accounts/answer/185833?hl=en เพื่อเอามาใช้เป็นเมลส่ง OTP 
4.2.1 https://temp-mail.org/ เอาไว้ใช้เป็น เมล สำหรับลอง test ส่ง OTP 
4.3 ติดตั้ง pip install alembic จะมีไฟล์ที่เกี่ยวกับ alembic.ini
4.4 ใช้คำสั่งนี้ไหนการ รัน uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
*/

/*
ติดตั้ง Alembic 
1. pip install alembic
2. lembic --version
3. เข้าไปเเก้ไขไฟล์ alembic.ini
4. alembic revision --autogenerate -m "initial migration"
5. alembic upgrade head
*/

