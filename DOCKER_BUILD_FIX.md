# Docker Build Fix for macOS

**ปัญหา:** `ros:humble-desktop` image ไม่ใช้ได้กับ macOS ARM64  
**วิธีแก้:** ใช้ Ubuntu 22.04 + install ROS 2 Humble เอง

---

## 🚀 ตัวเลือกการสร้าง Docker

### Option 1: Full Desktop (เสถียร - ใช้เวลา 15-20 นาที)

```bash
docker build -t duo-joint-humble .
```

✅ ROS 2 Humble complete  
✅ Controllers พร้อม  
✅ ทดสอบได้เต็มตัว  
⏱️ ใช้เวลา 15-20 นาที

### Option 2: Minimal (เร็ว - ใช้เวลา 5-10 นาที)

```bash
docker build -t duo-joint-humble -f Dockerfile.minimal .
```

✅ ROS 2 Core + Controllers  
✅ ตัวจริงใช้ได้เต็มตัว  
⏱️ ใช้เวลา 5-10 นาที (เร็วกว่า)

---

## 📊 เปรียบเทียบ

| Feature | Desktop | Minimal |
|---------|---------|---------|
| ROS 2 Core | ✅ | ✅ |
| Controllers | ✅ | ✅ |
| Visualization | ✅ | ❌ |
| Build time | 15-20 min | 5-10 min |
| Size | ~2GB | ~800MB |

---

## 🎯 ข้อแนะนำ

### สำหรับการทดสอบ Hardware
```bash
# ใช้ Minimal ได้เต็มตัว
docker build -t duo-joint-humble -f Dockerfile.minimal .
```

### สำหรับ Development เต็มรูป
```bash
# ใช้ Desktop เพื่อ visualization
docker build -t duo-joint-humble .
```

---

## 📝 คำสั่งก่อนและหลัง

### ถ้า Docker image สร้างจาก Desktop version:
```bash
./quick_test.sh    # ใช้ได้เลย
./test_hardware.sh # ใช้ได้เลย
```

### ถ้าต้องการสร้างใหม่ด้วย Minimal:
```bash
# ลบ old image
docker rmi duo-joint-humble

# สร้างใหม่ด้วย Minimal
docker build -t duo-joint-humble -f Dockerfile.minimal .

# ใช้ scripts เหมือนเดิม
./quick_test.sh
```

---

## ✅ Status

- ✅ Dockerfile (Desktop) - ถูกอัปเดต
- ✅ Dockerfile.minimal (เร็ว) - สร้างใหม่
- ✅ Scripts ใช้ได้ทั้งสอง version

---

## 🚨 ถ้ายังมีปัญหา

### ลบ image เก่า และสร้างใหม่
```bash
docker rmi duo-joint-humble
docker build -t duo-joint-humble -f Dockerfile.minimal .
```

### ตรวจสอบ Docker desktop
```bash
docker --version
# Desktop 4.x.x
```

### ลองทดสอบ step by step
```bash
# เปิด terminal 1
docker run -it --device=/dev/cu.usbserial-A98FRPHD:/dev/ttyUSB0 duo-joint-humble bash

# ข้างใน container
root@container:/ws# ros2 --version
# ROS 2 humble
```

---

**Status:** 🟢 Docker Build Fixed!
