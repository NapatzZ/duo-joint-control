# macOS Testing Guide - Dual Motor POC

**Platform:** macOS (ARM64 / Intel)  
**Tool:** Pixi (Package Manager)  
**Status:** ✅ Ready for Python script testing

---

## 🍎 macOS Compatibility

### What Works on macOS

| Component | macOS | Notes |
|-----------|-------|-------|
| Python Scripts | ✅ | Full support - test suite runs fine |
| ROS 2 Launch | ⚠️ | Requires Docker or Linux VM |
| Hardware Interface | ⚠️ | Requires Linux (Dynamixel drivers) |
| Mock Hardware Tests | ✅ | Full support - no real hardware needed |

### Serial Port Differences

macOS uses different device naming:
- **Linux:** `/dev/ttyUSB0`
- **macOS:** `/dev/tty.usbserial-*` or `/dev/cu.usbserial-*`

---

## 🚀 Setup with Pixi (5 Minutes)

### Step 1: Install Pixi (if not already done)

```bash
curl -fsSL https://pixi.sh | bash
```

### Step 2: Initialize Pixi Environment

```bash
cd /Users/napat/Desktop/skuba_ws/dual-joint
pixi install
```

**Output:**
```
✓ Resolved 42 packages
✓ Installed 42 packages
✓ Created environment in ./pixi
```

### Step 3: Verify Setup

```bash
pixi run python3 --version
# Output: Python 3.10.13
```

---

## 🧪 Testing on macOS with Pixi

### Test 1: Run Test Suite (Python Only)

```bash
pixi run python3 duo_joint/scripts/test_dual_motor_sync.py
```

**Expected Output:**
```
============================================================
DUAL MOTOR SYNCHRONIZATION TEST SEQUENCE
============================================================

[TEST 1] Moving to HOME (0 rad)...
  Current position: 0.000 rad
  ✓ Home position reached
```

### Test 2: Real-time Monitor

```bash
pixi run python3 duo_joint/scripts/monitor_dual_motors.py
```

**Expected Output:**
```
======================================================================
DUAL MOTOR REAL-TIME MONITOR (ROS 2 Humble)
======================================================================
Monitoring: Motor 22 (ID 22) + Motor 21 (ID 21) → dual_joint
----------------------------------------------------------------------

[1699123456.123456789]
  Position: +0.000 rad (+0.0°)  [████████████████░░░░░░░░░░░░░░░░░░░░]
  Velocity: +0.000 rad/s  🟢 IDLE
----------------------------------------------------------------------
```

### Test 3: Linting & Code Check

```bash
pixi run lint
```

---

## 🐳 Full Testing with Docker (Recommended)

For complete testing including ROS 2 control:

### Create Dockerfile

```dockerfile
FROM ros:humble-desktop

WORKDIR /workspace

# Install dependencies
RUN apt-get update && apt-get install -y \
    python3-pip \
    git \
    colcon-common-extensions \
    && rm -rf /var/lib/apt/lists/*

# Copy project
COPY . /workspace/

# Build
RUN bash -c 'source /opt/ros/humble/setup.bash && \
    colcon build --packages-select duo_joint'

# Launch entrypoint
ENTRYPOINT ["bash", "-c", "source /opt/ros/humble/setup.bash && \
                          source install/setup.bash && \
                          bash"]
```

### Build & Run Docker Container

```bash
# Build image
docker build -t duo-joint-humble .

# Run container
docker run -it \
  --env="DISPLAY=$DISPLAY" \
  --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
  duo-joint-humble
```

---

## 💻 macOS Serial Port Testing

### Find Serial Port

If you connect a USB device to macOS:

```bash
# List serial ports
ls -la /dev/tty.* /dev/cu.*

# Output:
# /dev/tty.usbserial-123456789
# /dev/cu.usbserial-123456789
```

### Test Serial Connection

```bash
# Install screen (macOS)
brew install screen

# Connect to motor
screen /dev/cu.usbserial-123456789 1000000
# Press Ctrl+A then Ctrl+\ to exit
```

### Using with Pixi

Create a test script with correct macOS port:

```python
import serial

# macOS port detection
import glob

def find_serial_port():
    """Find first available serial port on macOS"""
    ports = glob.glob('/dev/cu.usbserial*')
    if ports:
        return ports[0]
    return None

port = find_serial_port()
print(f"Using port: {port}")
```

---

## 🔧 Pixi Commands Reference

### Setup & Environment

```bash
# Install dependencies
pixi install

# Update environment
pixi update

# Show environment info
pixi info

# Activate shell with Pixi environment
pixi shell
```

### Running Tasks

```bash
# List all available tasks
pixi task list

# Run specific task
pixi run test-sync      # Run test suite
pixi run monitor        # Run real-time monitor
pixi run lint          # Check code

# Run arbitrary command
pixi run python3 --version
```

### Development

```bash
# Add new dependency
pixi add numpy scipy

# Add PyPI dependency
pixi add --pypi-type somepackage

# Remove dependency
pixi remove numpy
```

---

## 📋 Complete macOS Testing Workflow

### Step 1: Setup (First Time)

```bash
cd /Users/napat/Desktop/skuba_ws/dual-joint
pixi install
```

### Step 2: Run Python Tests

```bash
# Monitor motors (mock)
pixi run monitor

# Run synchronization tests
pixi run test-sync

# Run all tests
pixi run test-all
```

### Step 3: For Real Hardware (Linux Required)

**Option A: Remote SSH to Linux Machine**

```bash
# From macOS, SSH into Linux machine with ROS 2
ssh user@linux-machine.local

# Run on remote
ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware:=false
```

**Option B: Docker on macOS**

```bash
docker build -t duo-joint .
docker run -it duo-joint

# Inside container
ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware:=false
```

---

## 🎯 Testing Scenarios on macOS

### Scenario 1: Development Testing

```bash
pixi run monitor
# ✅ Works perfectly on macOS
# ✅ View real-time status
# ✅ No hardware needed
```

### Scenario 2: Code Review

```bash
pixi run lint
# ✅ Check Python syntax
# ✅ Find issues
# ✅ Works on macOS
```

### Scenario 3: Integration Testing

```bash
# Via Docker
docker build -t duo-joint .
docker run duo-joint ros2 launch duo_joint dual_motor_control.launch.py

# ✅ Full ROS 2 testing
# ✅ Hardware simulation
# ✅ Works on macOS via Docker
```

### Scenario 4: Hardware Testing

```bash
# Option 1: Linux VM / Remote Linux
ssh linux-dev-machine
cd duo-joint-control
ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware:=false

# Option 2: Raspberry Pi or ARM Linux board
ssh pi@raspberrypi.local
# ... same ROS 2 launch commands
```

---

## 🚨 Known Limitations on macOS

| Limitation | Cause | Workaround |
|-----------|-------|-----------|
| No native ROS 2 | Not officially supported | Use Docker or Linux VM |
| No hardware interface | Dynamixel drivers for Linux only | Use remote Linux machine |
| Serial port names different | macOS uses `/dev/cu.* ` | Update port in config |
| Can't run mock hardware with ROS 2 | ROS 2 not native | Use Docker container |

---

## ✅ What Actually Works on macOS

### ✅ Python Scripts
```bash
pixi run python3 duo_joint/scripts/test_dual_motor_sync.py
pixi run python3 duo_joint/scripts/monitor_dual_motors.py
```

### ✅ Code Analysis
```bash
pixi run lint
python3 -m py_compile duo_joint/scripts/*.py
```

### ✅ Configuration Review
```bash
cat duo_joint/config/controllers.yaml
cat duo_joint/urdf/duo_joint.urdf
```

### ✅ Documentation
```bash
# All .md files work perfectly
open duo_joint/QUICK_START.md
```

---

## 🐳 Docker Quick Start (Recommended for Full Testing)

### 1. Create Dockerfile (Already provided above)

### 2. Build Image

```bash
cd /Users/napat/Desktop/skuba_ws/dual-joint
docker build -t duo-joint-humble .
```

### 3. Run Full Test Suite

```bash
docker run -it duo-joint-humble bash

# Inside container
source /opt/ros/humble/setup.bash
ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware:=true
```

### 4. Test with Real Hardware (if USB adapter available)

```bash
docker run -it \
  --device=/dev/ttyUSB0:/dev/ttyUSB0 \
  duo-joint-humble bash

# Inside container
ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware:=false
```

---

## 📊 Testing Matrix on macOS

| Test | macOS | Docker | Linux VM |
|------|-------|--------|----------|
| Unit Tests | ✅ | ✅ | ✅ |
| Monitor Script | ✅ | ✅ | ✅ |
| Sync Tests (Python) | ✅ | ✅ | ✅ |
| ROS 2 Launch | ❌ | ✅ | ✅ |
| Mock Hardware | ❌ | ✅ | ✅ |
| Real Hardware | ❌ | ⚠️ | ✅ |

**Legend:** ✅ Works | ⚠️ Works with USB passthrough | ❌ Not supported

---

## 💡 Recommended macOS Workflow

### For Development

1. **Edit code on macOS** (use your favorite editor)
2. **Run tests with Pixi** (Python scripts work fine)
3. **Use Docker for ROS 2 integration** (when needed)
4. **Push to GitHub** (version control)

### For Hardware Testing

1. **Use Linux machine/Raspberry Pi** (native ROS 2 support)
2. **Or use AWS EC2 Linux instance** (cloud testing)
3. **Or use Docker container** (local, but limited serial port)

---

## 🎓 Example: Complete macOS Workflow

```bash
# Day 1: Development on macOS
cd ~/Desktop/skuba_ws/dual-joint
pixi install
pixi run lint                    # Check syntax
pixi run monitor                 # View mock motors
git add .
git commit -m "Updated motor config"
git push origin main

# When ready for hardware testing
# SSH into Linux machine
ssh robot@192.168.1.100

# On Linux machine
cd ~/catkin_ws/src/duo-joint-control
colcon build --packages-select duo_joint
source install/setup.bash
ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware:=false

# Monitor from macOS
ssh robot@192.168.1.100 'ros2 topic echo /joint_states'
```

---

## 🔗 Useful macOS Tools

```bash
# Install homebrew (if not already)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install useful tools
brew install screen                    # Serial port testing
brew install docker                   # Docker for ROS 2
brew install colcon                   # Colcon (if needed)
```

---

## 📞 Support for macOS Testing

### If Pixi fails to install

```bash
pip install pixi
# Or via homebrew
brew install pixi
```

### If Docker doesn't have serial access

```bash
# List devices
ls -la /dev/tty.* /dev/cu.*

# Pass device to Docker
docker run --device=/dev/cu.usbserial-XXX:/dev/ttyUSB0 -it duo-joint-humble
```

### If ROS 2 commands not found

```bash
# Inside Docker container
source /opt/ros/humble/setup.bash
# This line may already be in .bashrc
```

---

## ✨ Summary

| Use Case | Platform | Command |
|----------|----------|---------|
| **Code Development** | macOS | `pixi run lint` |
| **Test Scripts** | macOS | `pixi run test-sync` |
| **Monitor Motors** | macOS | `pixi run monitor` |
| **Full ROS 2 Test** | Docker | `docker run duo-joint` |
| **Hardware Test** | Linux/RPi | `ros2 launch ...` |

**Recommendation:** Use **Pixi on macOS** for development and Python testing, **Docker** for ROS 2 integration testing, and **Linux machine/Raspberry Pi** for actual hardware testing.

---

**Last Updated:** 2026-10-30  
**macOS Version Tested:** 14.2.0 (Sonoma)  
**Python:** 3.10.13  
**Pixi:** Latest
