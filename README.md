# Car Rental Frontend

โปรเจคนี้เป็น frontend ของระบบเช่ารถ ที่สร้างด้วย React, TypeScript และ Vite

## ภาพรวม

เว็บแอปนี้รองรับ:

- หน้าเว็บหลายหน้าโดยใช้ React Router
- ระบบล็อกอิน / ลงทะเบียนผู้ใช้
- หน้าสำหรับผู้ดูแลระบบจัดการรถ
- ค้นหาและกรองรถยนต์
- กระบวนการเช่ารถและดูประวัติการเช่า
- ปุ่มสลับภาษาอังกฤษและไทย

ฝั่ง frontend จะเชื่อมต่อกับ backend ภายในโฟลเดอร์ `car-rental-backend/`

## Tech Stack

- React 19
- TypeScript
- Vite
- React Router DOM
- ESLint

## โครงสร้างโปรเจคหลัก

- `src/`
  - `App.tsx` - กำหนดเส้นทางของแอป (routes) และ provider หลัก
  - `i18n.jsx` - คอนเท็กซ์ภาษาพร้อมคำแปลภาษาอังกฤษ/ไทย
  - `AuthContext.jsx` - คอนเท็กซ์จัดการสถานะผู้ใช้
  - `components/` - คอมโพเนนต์ UI ที่ใช้ซ้ำได้ เช่น `Navbar`, `CarCard`, `ProtectedRoute`
  - `Pages/` - หน้าจอหลักของแอป เช่น `Dashboard`, `Login`, `Register`, `Cars`, `Rent`, `MyRentals`, `Profile`
  - `services/api.js` - ตัวเรียกใช้งาน API กับ backend
- `public/` - ไฟล์สาธารณะและ static assets
- `car-rental-backend/` - เซิร์ฟเวอร์ backend และ API (Express)

## การติดตั้งและรัน

### 1. ติดตั้ง dependencies frontend

```bash
npm install
```

### 2. ติดตั้ง dependencies backend

```bash
cd car-rental-backend
npm install
cd ..
```

### 3. รัน backend

```bash
cd car-rental-backend
npm run dev
```

จากนั้น backend จะเริ่มทำงานบนพอร์ตที่กำหนดใน `server.js`

### 4. รัน frontend

```bash
npm run dev
```

แล้วเปิด URL ที่ Vite แสดงในเทอร์มินัล

## คำสั่งสำคัญ

- `npm run dev` - รัน frontend ในโหมดพัฒนา
- `npm run build` - สร้างไฟล์สำหรับ production
- `npm run lint` - ตรวจสอบโค้ดด้วย ESLint
- `npm run format` - จัดรูปแบบโค้ดด้วย Prettier

## ข้อมูลหน้าโค้ดหลัก

- `src/App.tsx` - กำหนดเส้นทาง
- `src/i18n.jsx` - คำแปลภาษา
- `src/AuthContext.jsx` - จัดการ session ผู้ใช้
- `src/Pages/Dashboard.jsx` - หน้าหลัก
- `src/Pages/Login.jsx` - หน้าล็อกอิน
- `src/Pages/Register.jsx` - หน้าสมัครสมาชิก
- `src/Pages/Cars.jsx` - หน้าแสดงรถทั้งหมด
- `src/Pages/Rent.jsx` - หน้าเช่ารถ
- `src/Pages/MyRentals.jsx` - ดูประวัติการเช่า
- `src/Pages/Profile.jsx` - จัดการข้อมูลโปรไฟล์
- `src/components/ProtectedRoute.jsx` - ป้องกันหน้าเฉพาะผู้ใช้งานที่ล็อกอินแล้ว
- `src/services/api.js` - เรียก API ไปยัง backend

## คำอธิบายสั้น ๆ ของโปรเจค

ระบบ frontend สำหรับเว็บเช่ารถที่มี:

- หน้าแสดงรถและฟิลเตอร์
- การล็อกอิน/ลงทะเบียน
- การจัดการเช่ารถและดูประวัติการเช่า
- ระบบแอดมินสำหรับจัดการรถ
- รองรับภาษาอังกฤษและไทย

> เป็นโปรเจคเรียนรู้ที่ใช้ React + TypeScript + Vite และเชื่อมต่อกับ backend Express ในโฟลเดอร์ `car-rental-backend/`

## 🐳 รันทั้งระบบด้วย Docker (คำสั่งเดียว)

```bash
docker compose up
```

- เว็บ: http://localhost:5173 · API: http://localhost:5000/api
- สร้างฐานข้อมูลใหม่จาก `car-rental-backend/database/schema.sql` (ตาราง + stored procedures ทั้ง 14 ตัว) และใส่ข้อมูลตัวอย่างจาก `seed-demo.sql`
- บัญชีทดลอง: `demo_admin` / `Demo@2026` (แอดมิน), `demo_user` / `Demo@2026`
- ไม่แตะฐานข้อมูล MySQL ที่มีอยู่ในเครื่อง (ใช้ container แยก)

### อัปเดตฐานข้อมูลเดิม (ถ้าใช้ MySQL ของตัวเอง)
การเช่าตอนนี้บันทึก **จำนวนวัน, ราคารวม (คำนวณฝั่งเซิร์ฟเวอร์), ชื่อ, เบอร์, อีเมล, ที่อยู่** ของผู้เช่า และมีหน้า **Admin** (`/admin`) สำหรับเพิ่ม/แก้/ลบรถ และจัดการผู้ใช้
ฐานข้อมูลที่สร้างไว้ก่อนหน้าต้องเพิ่มคอลัมน์ใน `rentals` และสร้าง procedure ใหม่ ดูได้ใน `car-rental-backend/database/schema.sql` (ควรสำรองข้อมูลก่อน) — ส่วน `docker compose` สร้างฐานข้อมูลใหม่ให้อัตโนมัติ
เลขบัตรประชาชนในฟอร์มใช้ตรวจความครบถ้วนเท่านั้น ไม่ถูกส่งไปหรือเก็บในฐานข้อมูล

## 🌐 Live demo

https://driverent-whky.onrender.com — `demo_user` / `Demo@2026` · แอดมิน `demo_admin` / `Demo@2026` (ข้อมูลรีเซ็ตทุกครั้งที่เซิร์ฟเวอร์รีสตาร์ต)

### ฐานข้อมูล PostgreSQL (Supabase)
ตั้ง `DATABASE_URL` แล้ว API จะใช้ PostgreSQL แทน MySQL โดยอัตโนมัติ (ฟังก์ชันทั้งหมดอยู่ใน schema `driverent`)
สร้างตาราง: `psql "$DATABASE_URL" -f car-rental-backend/database/schema-pg.sql -f car-rental-backend/database/seed-demo-pg.sql`
เว็บที่ใช้งานจริงใช้ Supabase นี้ ข้อมูลจึงไม่หายเมื่อเซิร์ฟเวอร์รีสตาร์ต
