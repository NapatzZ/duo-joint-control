# Docker Setup - ROS 2 Humble on macOS

**ใช้ Docker เพื่อรันได้ทั้ง macOS และสามารถต่อ hardware ได้**

---

## 🚀 ติดตั้ง Docker

### macOS
```bash
# ติดตั้ง Docker Desktop
brew install --cask docker

# เปิด Docker Desktop จาก Applications
# หรือ
open /Applications/Docker.app
```

### ตรวจสอบการติดตั้ง
```bash
docker --version
docker-compose --version
```

---

## 🏗️ สร้าง Docker Image

```bash
cd /Users/napat/Desktop/skuba_ws/dual-joint

# Build image (ครั้งแรกจะใช้เวลา 5-10 นาที)
docker build -t duo-joint-humble .

# หรือใช้ docker-compose
docker-compose build
```

**Output:**
```
Successfully built abc123def456
Successfully tagged duo-joint-humble:latest
```

---

## 🎮 รันได้ 3 แบบ

### วิธี 1️⃣ : Docker run (ง่ายสุด - Mock Hardware)

```bash
# เปิด container
docker run -it duo-joint-humble

# ข้างในจะเป็น bash # ของ ROS 2

# ลองคำสั่ง ROS 2
root@container:/ws# ros2 --version
# ROS 2 humble (12.x.x - ...)

# ออกจากคำสั่ง
root@container:/ws# exit
```

### วิธี 2️⃣ : Docker Compose (ง่าย + บำรุงรักษาได้)

```bash
# Start container
docker-compose up -d

# เข้า container
docker-compose exec duo-joint-ros2 bash

# ลองคำสั่ง
root@container:/ws# ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware:=true

# ออกจาก container
root@container:/ws# exit

# ปิด container
docker-compose down
```

### วิธี 3️⃣ : Docker with Hardware (ต่อ Motors จริง)

```bash
# สำหรับ Linux: ต่อ USB ได้เลย
docker run -it --device=/dev/ttyUSB0:/dev/ttyUSB0 duo-joint-humble

# สำหรับ macOS: ต้องหา serial port ก่อน
ls /dev/cu.usbserial*
# output: /dev/cu.usbserial-123456789

# ต่อ Docker
docker run -it --device=/dev/cu.usbserial-123456789:/dev/ttyUSB0 duo-joint-humble
```

---

## 📋 ทดสอบในขั้นตอน

### ขั้น 1: Mock Hardware Test (ไม่ต้องมี Motors)

```bash
docker run -it duo-joint-humble bash

# ข้างใน container
root@container:/ws# source /opt/ros/humble/setup.bash
root@container:/ws# source install/setup.bash

# ลาญช์ด้วย mock hardware
root@container:/ws# ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware:=true

# ใน terminal อื่น:
docker exec -it $(docker ps -q) bash
root@container:/ws# ros2 topic echo /joint_states
```

### ขั้น 2: Real Hardware Test (มี Motors)

```bash
# ต่อ USB Motors ก่อน
# แล้ว find port
ls /dev/cu.usbserial*

# เปิด Docker with serial port
docker run -it --device=/dev/cu.usbserial-123456789:/dev/ttyUSB0 duo-joint-humble

# ข้างใน container
root@container:/ws# source /opt/ros/humble/setup.bash
root@container:/ws# source install/setup.bash

# ลาญช์ด้วย REAL hardware
root@container:/ws# ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware:=false
```

---

## 📊 มี 2 Terminals

### Terminal 1: Launch (ควบคุม Motors)
```bash
docker run -it --device=/dev/cu.usbserial-123456789:/dev/ttyUSB0 duo-joint-humble bash

# ข้างใน:
root@container:/ws# source /opt/ros/humble/setup.bash
root@container:/ws# source install/setup.bash
root@container:/ws# ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware:=false
```

### Terminal 2: Monitor (ดูสถานะ)
```bash
docker exec -it $(docker ps -q) bash

# ข้างใน:
root@container:/ws# source /opt/ros/humble/setup.bash
root@container:/ws# source install/setup.bash

# ดูสถานะ joint
root@container:/ws# ros2 topic echo /joint_states

# หรือดูเป็น Python monitor
root@container:/ws# python3 install/duo_joint/lib/duo_joint/monitor_dual_motors.py
```

### Terminal 3: Send Commands
```bash
docker exec -it $(docker ps -q) bash

# ข้างใน:
root@container:/ws# source /opt/ros/humble/setup.bash
root@container:/ws# source install/setup.bash

# ส่ง command ไปยัง motors
root@container:/ws# ros2 topic pub /joint_trajectory_controller/joint_trajectory \
trajectory_msgs/JointTrajectory \
"header: {stamp: now, frame_id: ''}, 
 joint_names: ['dual_joint'],
 points: [{positions: [0.5], velocities: [0.0], time_from_start: {sec: 3}}]"
```

---

## 🔍 ค้นหา Serial Port บน macOS

```bash
# ดูทุก serial ports
ls /dev/cu.* /dev/tty.*

# Output example:
# /dev/cu.Bluetooth-Incoming-Port
# /dev/cu.usbserial-123456789     ← ตัวนี้ คือ USB adapter

# ใช้ screen เพื่อทดสอบ
screen /dev/cu.usbserial-123456789 1000000
# (Ctrl+A แล้ว Ctrl+\ เพื่อออก)
```

---

## 🐳 Docker Useful Commands

```bash
# ดู images
docker images | grep duo-joint

# ดู running containers
docker ps

# ดู all containers (รวม stopped)
docker ps -a

# ลบ container
docker rm <container_id>

# ลบ image
docker rmi duo-joint-humble

# ดู logs
docker logs <container_id>

# ดู resource usage
docker stats
```

---

## ⚙️ แก้ไข Code ใน Container

### วิธี 1: แก้ไขบน macOS, Auto-sync to Container

```bash
# ในนั้น docker-compose.yml มี volume mounting
volumes:
  - .:/ws

# คุณแก้ไข file บน macOS ที่ /Users/napat/Desktop/skuba_ws/dual-joint
# มันจะ sync เข้า container โดยอัตโนมัติ
```

### วิธี 2: แก้ไขภายใน Container

```bash
docker exec -it <container_id> nano /ws/duo_joint/config/controllers.yaml

# หรือเปิด bash และแก้ไข
docker exec -it <container_id> bash
root@container:/ws# nano duo_joint/config/controllers.yaml
```

---

## 🚀 Quick Start Command

```bash
# สร้าง image
docker build -t duo-joint-humble .

# รัน container
docker run -it duo-joint-humble

# ข้างใน container:
root@container:/ws# source /opt/ros/humble/setup.bash
root@container:/ws# source install/setup.bash
root@container:/ws# ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware:=true

# ใน terminal อื่น:
docker exec -it $(docker ps -q) bash
root@container:/ws# ros2 topic echo /joint_states
```

---

## 📝 Files

- **Dockerfile** - ROS 2 Humble image definition
- **docker-compose.yml** - Docker compose configuration (easier to manage)

---

## 🎯 เพิ่มเติม

### ถ้าต้องการ recompile หลังแก้ไข code:

```bash
docker run -it duo-joint-humble bash

root@container:/ws# source /opt/ros/humble/setup.bash
root@container:/ws# colcon build --packages-select duo_joint
root@container:/ws# source install/setup.bash
```

### ถ้า Motors ไม่ response:

```bash
# ตรวจสอบ port ว่าถูก
ls /dev/cu.* | grep usb

# ตรวจสอบ baud rate
screen /dev/cu.usbserial-XXX 1000000

# ตรวจสอบด้วย Dynamixel Wizard ก่อนต่อ Docker
```

---

## ✅ Checklist

- [ ] Docker Desktop ติดตั้ง
- [ ] Image สร้างสำเร็จ (`docker build -t duo-joint-humble .`)
- [ ] Container รัน (`docker run -it duo-joint-humble`)
- [ ] ROS 2 พร้อม (`ros2 --version` ข้างใน container)
- [ ] Package สร้าง (`ls /ws/install/duo_joint`)
- [ ] Test launch success (`ros2 launch duo_joint ...`)

---

**Status:** 🟢 Docker Ready to Use!
