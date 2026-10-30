# Hardware Test Guide - /dev/cu.usbserial-A98FRPHD

**ทดสอบมอเตอร์จริงบน macOS ด้วย Docker**

---

## 🚀 ทดสอบแบบ 30 วินาที

```bash
cd /Users/napat/Desktop/skuba_ws/dual-joint
./quick_test.sh
```

**ปนี:**
- ✅ เช็ค serial port
- ✅ สร้าง Docker image (ครั้งแรก)
- ✅ เปิด ROS 2 controller
- ✅ ต่อมอเตอร์จริง

---

## 🎮 ทดสอบแบบเต็ม (Interactive Menu)

```bash
./test_hardware.sh
```

**เมนูตัวเลือก:**
```
1) Launch ROS 2 Controller
2) Monitor Joint States
3) Run Automated Test Sequence
4) Interactive Mode (send custom commands)
5) Full Test (ทั้งหมด)
6) Clean up
0) Exit
```

---

## 📋 ตัวเลือก Mode

### Real Hardware (ต่อมอเตอร์จริง)
```bash
./test_hardware.sh real      # (Default)
```

### Mock Hardware (ไม่ต่อมอเตอร์)
```bash
./test_hardware.sh mock
```

---

## 🔧 Serial Port Details

```
Port: /dev/cu.usbserial-A98FRPHD
Baud Rate: 1000000
Motors: MX106 (IDs 22, 21)
```

---

## 📊 Script ที่มี

| Script | ใช้สำหรับ | เวลา |
|--------|---------|------|
| `quick_test.sh` | ทดสอบเร็ว | 30 วิ |
| `test_hardware.sh` | ทดสอบเต็มรูป | 5 นาที |
| `test_hardware.sh real` | Real hardware | 5 นาที |
| `test_hardware.sh mock` | Mock (ไม่ต้อง motors) | 5 นาที |

---

## 🎯 ขั้นตอน

### ขั้น 1: ทดสอบเร็ว
```bash
./quick_test.sh
```

### ขั้น 2: ทดสอบเต็ม
```bash
./test_hardware.sh
# เลือก option 5 (Full Test)
```

### ขั้น 3: ส่งคำสั่งเอง (Interactive)
```bash
./test_hardware.sh
# เลือก option 4 (Interactive Mode)
# ส่ง position เช่น: 0.5, -1.0, 1.5
```

---

## 🔍 ตรวจสอบ Serial Port

```bash
# ดูทุก serial ports
ls /dev/cu.usbserial*

# เช็คว่า port ของเราอยู่ที่
ls /dev/cu.usbserial-A98FRPHD

# ทดสอบ baud rate
screen /dev/cu.usbserial-A98FRPHD 1000000
# (Ctrl+A แล้ว Ctrl+\ เพื่อออก)
```

---

## 📊 เห็น Output แบบไหน

### Successful Launch
```
✅ Docker image found
✅ Serial port detected: /dev/cu.usbserial-A98FRPHD
✅ Serial port is readable/writable

🚀 Starting ROS 2 Controller

[INFO] [ros2_control_node] controller_manager starting...
[INFO] [controller_manager] Loading controller 'joint_trajectory_controller'
[INFO] [controller_manager] Started controllers with state 'active'
```

### Joint State Output
```
header:
  stamp:
    sec: 1699123456
    nanosec: 123456789
  frame_id: ''
name: ['dual_joint']
position: [0.543]
velocity: [0.001]
```

### Test Command Success
```
Topic: /joint_trajectory_controller/joint_trajectory
Publishing 1 message(s)
```

---

## 🚨 Troubleshooting

### ❌ "Serial port not found"
```bash
# ตรวจสอบ port
ls /dev/cu.usbserial*

# อัปเดต port ใน script
nano quick_test.sh
# แก้ SERIAL_PORT="/dev/cu.usbserial-YOUR-PORT"
```

### ❌ "Permission denied"
```bash
sudo chmod 666 /dev/cu.usbserial-A98FRPHD
```

### ❌ "Docker image not found"
```bash
# สร้าง image ใหม่
docker build -t duo-joint-humble .
```

### ❌ "Motor doesn't respond"
```bash
# ตรวจสอบ motor ID ด้วย Dynamixel Wizard
# แน่ใจว่า baud rate = 1000000
# ลองปลดเก็บ power แล้วเปิดใหม่
```

---

## 💡 Advanced

### ดู Docker logs
```bash
docker logs duo-joint-hw-test
```

### ป้อนคำสั่ง ROS 2 เอง
```bash
docker exec -it duo-joint-hw-test bash

# ข้างใน
root@container:/ws# source /opt/ros/humble/setup.bash
root@container:/ws# source install/setup.bash
root@container:/ws# ros2 topic list
root@container:/ws# ros2 topic echo /joint_states
```

### ปิด container ทำความสะอาด
```bash
./test_hardware.sh
# เลือก option 6 (Clean up)
```

---

## ✅ Success Checklist

- [ ] Serial port `/dev/cu.usbserial-A98FRPHD` visible
- [ ] `./quick_test.sh` รันสำเร็จ
- [ ] เห็น `controller_manager` starting...
- [ ] เห็น `/joint_states` topic
- [ ] มอเตอร์ตอบสนอง

---

**Status:** 🟢 Ready to Test!
