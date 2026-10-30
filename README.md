# Dual Motor Joint Control - ROS 2 Humble POC

**Proof of Concept for synchronized dual Dynamixel motors on a single joint**

Synchronizes two MX106 Dynamixel motors (IDs 22 & 21) to increase load capacity and provide redundancy for the dual-joint mechanism.

[![Status](https://img.shields.io/badge/Status-POC%20Ready-green)]()
[![ROS2](https://img.shields.io/badge/ROS2-Humble-blue)]()
[![Hardware](https://img.shields.io/badge/Hardware-MX106-orange)]()

---

## 📋 Overview

This project demonstrates synchronized dual motor control using:
- **ROS 2 Humble** (latest LTS)
- **ros2_control** framework
- **Dynamixel Hardware Interface**
- **Transmission matrices** for motor synchronization

### Hardware Setup
```
Motor 22 (MX106) ┐
                  ├─→ dual_joint (synchronized)
Motor 21 (MX106) ┘
```

**Expected Performance:**
- Single Motor Torque: 6 Nm
- Dual Motor Torque: ~12 Nm (2×)
- Load Capacity: Doubled
- Speed: Same (60 RPM)

---

## 🚀 Quick Start (5 Minutes)

### Prerequisites

```bash
# ROS 2 Humble installation
sudo apt install ros-humble-desktop

# Required packages
sudo apt install \
  ros-humble-controller-manager \
  ros-humble-joint-trajectory-controller \
  ros-humble-robot-state-publisher \
  build-essential cmake
```

### Clone & Build

```bash
# Clone repository
git clone https://github.com/NapatzZ/duo-joint-control.git
cd duo-joint-control

# Build
colcon build --packages-select duo_joint
source install/setup.bash
```

### Launch (Three Terminals)

**Terminal 1 - Launch Controller:**
```bash
ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware:=false
```

**Terminal 2 - Monitor Motors:**
```bash
python3 install/duo_joint/lib/duo_joint/monitor_dual_motors.py
```

**Terminal 3 - Send Commands:**
```bash
# Move to 0.5 rad
ros2 topic pub /joint_trajectory_controller/joint_trajectory \
trajectory_msgs/JointTrajectory \
"header: {stamp: now, frame_id: ''}, 
 joint_names: ['dual_joint'],
 points: [{positions: [0.5], velocities: [0.0], time_from_start: {sec: 3}}]"
```

✅ **Both motors should move together!**

---

## 📚 Full Documentation

| Document | Purpose |
|----------|---------|
| **[QUICK_START.md](duo_joint/QUICK_START.md)** | 60-second quick reference |
| **[DUAL_MOTOR_POC.md](duo_joint/DUAL_MOTOR_POC.md)** | Complete technical guide |
| **[IMPLEMENTATION_SUMMARY.md](duo_joint/IMPLEMENTATION_SUMMARY.md)** | Architecture & configuration |
| **[SETUP_VERIFICATION.md](SETUP_VERIFICATION.md)** | Setup checklist |

---

## 🔧 System Architecture

```
┌─────────────────────────────────────────────────┐
│         ROS 2 Humble (ros2_control)             │
│                                                 │
│  robot_state_publisher                          │
│  controller_manager (ros2_control_node)         │
│  joint_trajectory_controller                    │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│    Dynamixel Hardware Interface                 │
│    Transmission Matrix: [1, 1]                  │
│    (1 joint × 2 motors)                         │
└─────────────────────────────────────────────────┘
         ↓ Motor 22        ↓ Motor 21
    ┌─────────────┐    ┌─────────────┐
    │   MX106     │    │   MX106     │
    │   ID: 22    │    │   ID: 21    │
    └─────────────┘    └─────────────┘
         ↓                    ↓
    ┌──────────────────────────────┐
    │  Dual Joint (synchronized)   │
    └──────────────────────────────┘
```

---

## 🎮 Common Commands

### Launch with Different Options

```bash
# Real motors (default)
ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware:=false

# Mock hardware (testing without motors)
ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware:=true

# Custom serial port
ros2 launch duo_joint dual_motor_control.launch.py \
  port_name:=/dev/ttyUSB1 \
  baud_rate:=115200
```

### Monitor & Diagnose

```bash
# Real-time motor monitoring
python3 install/duo_joint/lib/duo_joint/monitor_dual_motors.py

# View raw joint states
ros2 topic echo /joint_states

# View controller status
ros2 topic echo /joint_trajectory_controller/state

# List all controllers
ros2 control list_controllers

# List hardware interfaces
ros2 control list_hardware_interfaces
```

### Position Commands

```bash
# Move to home (0 rad)
ros2 topic pub --once /joint_trajectory_controller/joint_trajectory \
trajectory_msgs/JointTrajectory \
"header: {stamp: now, frame_id: ''}, 
 joint_names: ['dual_joint'],
 points: [{positions: [0.0], velocities: [0.0], time_from_start: {sec: 2}}]"

# Move to +1.0 rad (57 degrees)
ros2 topic pub --once /joint_trajectory_controller/joint_trajectory \
trajectory_msgs/JointTrajectory \
"header: {stamp: now, frame_id: ''}, 
 joint_names: ['dual_joint'],
 points: [{positions: [1.0], velocities: [0.0], time_from_start: {sec: 3}}]"

# Move to -1.0 rad (-57 degrees)
ros2 topic pub --once /joint_trajectory_controller/joint_trajectory \
trajectory_msgs/JointTrajectory \
"header: {stamp: now, frame_id: ''}, 
 joint_names: ['dual_joint'],
 points: [{positions: [-1.0], velocities: [0.0], time_from_start: {sec: 3}}]"
```

---

## 🧪 Testing

### Test 1: Mock Hardware (No Motors Required)

```bash
# Launch with mock
ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware:=true

# In new terminal, check joint states
ros2 topic echo /joint_states | head -10

# Should output:
# name: ['dual_joint']
# position: [0.0]
# velocity: [0.0]
```

### Test 2: Real Hardware Synchronization

```bash
# Terminal 1: Launch
ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware:=false

# Terminal 2: Monitor
python3 install/duo_joint/lib/duo_joint/monitor_dual_motors.py

# Terminal 3: Run test suite
python3 install/duo_joint/lib/duo_joint/test_dual_motor_sync.py
```

**Expected Results:**
- ✅ Both motors move together
- ✅ Position error < 0.05 rad (2.9°)
- ✅ No error messages
- ✅ Motor temps < 60°C

### Test 3: Data Logging

```bash
# Record motor movements
ros2 bag record /joint_states -o dual_motor_log

# Playback recording
ros2 bag play dual_motor_log
```

---

## ⚙️ Configuration

### Motor Parameters (`config/controllers.yaml`)

```yaml
motor_22:
  id: 22
  model: "MX106"
  torque_limit: 1000  # mA - increase for higher load
  velocity_limit: 100  # RPM - lower = more stable
  temperature_limit: 70  # °C - safety threshold

motor_21:
  id: 21
  model: "MX106"
  torque_limit: 1000
  velocity_limit: 100
  temperature_limit: 70
```

### Controller Tuning (`config/controllers.yaml`)

```yaml
gains:
  dual_joint:
    p: 100.0   # Proportional - increase for faster response
    i: 0.0     # Integral - keep zero for stability
    d: 10.0    # Derivative - damping
```

**Tuning Tips:**
- Increase `p` if joint is sluggish
- Increase `d` if overshooting
- Increase `torque_limit` for heavier loads

---

## 🔴 Emergency Stop

If motors are out of control:

```bash
# Option 1: Stop the launch
^C  # (Press Ctrl+C in launch terminal)

# Option 2: Kill the process
pkill -f "ros2 launch duo_joint"

# Option 3: Disable torque manually
# Use Dynamixel Wizard 2 to set Torque Enable = 0
```

---

## 🐛 Troubleshooting

### Motors don't move

**Diagnostics:**
```bash
ros2 topic echo /joint_states
ros2 control list_controllers
```

**Solutions:**
- Check serial port: `ls /dev/ttyUSB*`
- Check motor IDs with Dynamixel Wizard 2
- Verify baud rate (should be 1000000)
- Check cable connections
- Verify power supply (12V for MX106)

### Motors move separately (not synchronized)

**Causes:**
- Mechanical misalignment
- Motor calibration offset
- Transmission matrix error

**Fix:**
```bash
# Check transmission matrix in duo_joint/urdf/duo_joint.urdf
# Should be: transmission_to_joint_matrix: 1, 1
```

### Motor overheating

**Solutions:**
- Reduce `torque_limit` in `config/controllers.yaml`
- Reduce `velocity_limit`
- Add cooling (fan or heat sink)
- Reduce duty cycle (rest periods)

### Serial connection timeout

**Solutions:**
```bash
# Check USB connection
lsusb

# Reset USB device
sudo systemctl restart systemd-udevd

# Change port permissions
sudo chmod 666 /dev/ttyUSB0

# Try different port
ros2 launch duo_joint dual_motor_control.launch.py port_name:=/dev/ttyUSB1
```

---

## 📁 Project Structure

```
duo-joint-control/
├── duo_joint/                          # Main ROS 2 package
│   ├── urdf/
│   │   └── duo_joint.urdf             # Robot model with ros2_control
│   ├── launch/
│   │   └── dual_motor_control.launch.py # Main launch file
│   ├── config/
│   │   └── controllers.yaml           # Motor & controller config
│   ├── scripts/
│   │   ├── test_dual_motor_sync.py    # Automated tests
│   │   └── monitor_dual_motors.py     # Real-time monitor
│   ├── CMakeLists.txt
│   ├── package.xml
│   ├── QUICK_START.md
│   ├── DUAL_MOTOR_POC.md
│   └── IMPLEMENTATION_SUMMARY.md
│
├── dynamixel_hardware_interface/       # Hardware interface
├── dynamixel_interfaces/               # ROS 2 messages
├── SETUP_VERIFICATION.md               # Setup checklist
└── README.md                           # This file
```

---

## 📊 Performance Metrics

| Metric | Single Motor | Dual Motors | Improvement |
|--------|--------------|-------------|------------|
| Max Torque | 6 Nm | ~12 Nm | 2.0× |
| Max Load | 5 kg | ~10 kg | 2.0× |
| Speed | 60 RPM | 60 RPM | 1.0× |
| Power Draw | 1× | ~2× | 2.0× |
| Heat | Normal | Higher | 1.5× |

---

## 🎓 Transmission Matrix

### How It Works

```
Command: dual_joint = 1.0 rad
            ↓
    [Transmission Matrix]
            ↓
Motor 22: 1.0 × 1.0 = 1.0 rad command
Motor 21: 1.0 × 1.0 = 1.0 rad command
            ↓
    Both move to 1.0 rad (SYNCHRONIZED)
```

### Matrix Definition

```xml
<param name="transmission_to_joint_matrix">
  1, 1  <!-- Both motors equally contribute to joint -->
</param>
```

---

## 🔗 Dependencies

- **ROS 2 Humble** (Humble Hawksbill, May 2022 - May 2027)
- **ros2_control** 4.0+
- **dynamixel_hardware_interface** (included)
- **dynamixel_interfaces** (included)
- **joint_trajectory_controller**

---

## 📝 References

- **ROS 2 Control:** https://control.ros.org/
- **Dynamixel Docs:** https://emanual.robotis.com/
- **Humble Release:** https://docs.ros.org/en/humble/

---

## ✅ Verification Checklist

- [ ] Build completes without errors
- [ ] Mock hardware test passes
- [ ] `/joint_states` topic publishes
- [ ] Real motors respond to commands
- [ ] Both motors move together
- [ ] Position error < 0.05 rad
- [ ] No overcurrent errors
- [ ] Motor temps < 60°C during operation

---

## 🚧 Next Steps (Post-POC)

- [ ] Integrate into main SKUBA arm URDF
- [ ] Add trajectory planning
- [ ] Implement load balancing algorithm
- [ ] Add individual motor diagnostics
- [ ] Thermal management system
- [ ] Fault detection (one motor fails)
- [ ] Production testing & validation

---

## 📞 Support

### Quick Debug Commands

```bash
# Check ROS 2 setup
ros2 --version

# Verify package is built
ros2 pkg list | grep duo_joint

# List available topics
ros2 topic list -v

# Monitor all parameters
ros2 param list

# Check node status
ros2 node list
```

### Getting Help

1. **Check documentation:** `duo_joint/QUICK_START.md`
2. **Review full guide:** `duo_joint/DUAL_MOTOR_POC.md`
3. **Check troubleshooting:** See section above
4. **Review logs:** Check ROS 2 topic outputs

---

## 📄 License

This project is provided as-is for research and development purposes.

---

## 👤 Author

**SKUBA R&D Team**  
Email: napat559977@gmail.com  
Date: 2026-10-30

---

## 🏷️ Version

**v0.1** - Initial POC Release  
Status: 🟢 **Ready for Testing**

---

**Last Updated:** 2026-10-30  
**Maintained By:** SKUBA R&D Team  
**GitHub:** https://github.com/NapatzZ/duo-joint-control
