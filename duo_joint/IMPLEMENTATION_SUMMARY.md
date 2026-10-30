# Dual Motor POC - Implementation Summary

**Date:** 2026-10-30  
**Status:** ✅ Complete & Ready for Testing  
**Platform:** ROS 2 Humble  
**Hardware:** Dynamixel MX106 (IDs 22 & 21)

---

## 📋 What Was Done

### 1. ✅ URDF Configuration (`urdf/duo_joint.urdf`)

Added ROS 2 Control section with:
- **2 Dynamixel motors** (IDs 22 & 21)
- **1 synchronized joint** (dual_joint)
- **Transmission matrix:** 1×2 (1 joint, 2 motors)
- Both motors contribute equally to joint movement

**Key Configuration:**
```xml
<param name="number_of_joints">1</param>
<param name="number_of_transmissions">2</param>
<param name="transmission_to_joint_matrix">
  1, 1  <!-- Both motors drive same joint -->
</param>
```

### 2. ✅ ROS 2 Humble Launch File

**File:** `launch/dual_motor_control.launch.py`

Features:
- Python-based launch (ROS 2 native)
- Robot State Publisher integration
- Controller Manager setup
- Mock hardware support for testing
- Configurable port and baud rate

**Usage:**
```bash
ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware:=false
```

### 3. ✅ Controller Configuration (`config/controllers.yaml`)

Includes:
- **Joint Trajectory Controller** - position-based trajectory following
- **Motor parameters** - torque limits, velocity limits, temperature thresholds
- **PID gains** - tuned for smooth motion
- **Safety parameters** - watchdog timeout, position error threshold

### 4. ✅ Testing & Monitoring Scripts

**Test Suite** (`scripts/test_dual_motor_sync.py`):
- Automated position commands (0 → 1.0 → -1.0 → 0 rad)
- Synchronization error monitoring
- Performance logging
- Ready for CI/CD integration

**Monitor** (`scripts/monitor_dual_motors.py`):
- Real-time position/velocity display
- Status visualization with progress bars
- Color-coded movement indication

### 5. ✅ Documentation

| Document | Purpose |
|----------|---------|
| `DUAL_MOTOR_POC.md` | Comprehensive technical documentation |
| `QUICK_START.md` | 60-second quick reference |
| `IMPLEMENTATION_SUMMARY.md` | This file - what was implemented |

### 6. ✅ Package Configuration

- **package.xml** - Updated to ROS 2 Humble format (ament_cmake)
- **CMakeLists.txt** - Updated to ROS 2 Humble (ament_cmake)
- All dependencies properly declared

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────┐
│         ROS 2 Controller Manager                    │
│  (ros2_control_node + joint_trajectory_controller)  │
└─────────────────────────────────────────────────────┘
                        ↓ commands
┌─────────────────────────────────────────────────────┐
│    Dynamixel Hardware Interface                     │
│  (transmission matrix: [1, 1])                      │
└─────────────────────────────────────────────────────┘
         ↓ Motor 22        ↓ Motor 21
    ┌─────────────┐    ┌─────────────┐
    │   MX106     │    │   MX106     │
    │   ID 22     │    │   ID 21     │
    └─────────────┘    └─────────────┘
         ↓                    ↓
    ┌──────────────────────────────┐
    │  Dual Joint (synchronized)   │
    └──────────────────────────────┘
```

---

## 🔧 Transmission Matrix Explanation

### What It Does

```
Command: joint_position = 1.0 rad
                  ↓
        transmission_to_joint_matrix × command
                  ↓
Motor_22_command = 1.0 rad
Motor_21_command = 1.0 rad
                  ↓
        Both motors move to 1.0 rad
```

### Matrix Format

```
              Motor_22  Motor_21
dual_joint  [   1        1    ]
```

- **1** = motor contributes to joint
- **0** = motor doesn't affect joint
- Value > 1 = motor contributes with gain

### Feedback Path

```
Motor_22_position = 0.5 rad
Motor_21_position = 0.5 rad
                  ↓
        joint_to_transmission_matrix × states
                  ↓
dual_joint_position = (0.5 + 0.5) / 2 = 0.5 rad
```

---

## 🚀 How to Use

### Minimal Quickstart

```bash
# Terminal 1: Launch
cd /Users/napat/Desktop/skuba_ws/dual-joint
source install/setup.bash
ros2 launch duo_joint dual_motor_control.launch.py

# Terminal 2: Monitor
python3 install/duo_joint/lib/duo_joint/monitor_dual_motors.py

# Terminal 3: Command
ros2 topic pub /joint_trajectory_controller/joint_trajectory \
trajectory_msgs/JointTrajectory \
"header: {stamp: now, frame_id: ''}, 
 joint_names: ['dual_joint'],
 points: [{positions: [0.5], velocities: [0.0], time_from_start: {sec: 3}}]"
```

### Full Testing Sequence

```bash
# Step 1: Verify setup with mock hardware
ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware:=true

# Step 2: Check /joint_states topic exists
ros2 topic echo /joint_states

# Step 3: Run with real motors (low torque first!)
ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware:=false

# Step 4: Monitor synchronization
python3 src/duo_joint/scripts/monitor_dual_motors.py

# Step 5: Run test suite
python3 src/duo_joint/scripts/test_dual_motor_sync.py
```

---

## ✅ Verification Checklist

### Hardware Level
- [ ] Motor 22 responds to commands
- [ ] Motor 21 responds to commands
- [ ] Both on same RS485 bus
- [ ] Serial port detected: `/dev/ttyUSB0` (or configured)
- [ ] Baud rate: 1000000
- [ ] Mechanical coupling works (not binding)

### Software Level
- [ ] URDF parses without errors
- [ ] Controller manager starts
- [ ] `/joint_states` topic published
- [ ] `dual_joint` visible in joint list
- [ ] Transmission matrix applied correctly

### Synchronization Level
- [ ] Both motors receive identical commands
- [ ] Both motors move together
- [ ] Position error < 0.05 rad (2.9°)
- [ ] Velocity synchronized
- [ ] No sustained error messages

### Performance Level
- [ ] Motors move smoothly (no jerking)
- [ ] Load capacity doubled vs. single motor
- [ ] Temperature < 60°C during normal operation
- [ ] No overcurrent faults
- [ ] Command latency < 100ms

---

## 📊 Configuration Reference

### Motor Parameters

| Parameter | Value | Notes |
|-----------|-------|-------|
| Motor 22 ID | 22 | Primary motor |
| Motor 21 ID | 21 | Dual motor |
| Model | MX106 | 6 Nm torque each |
| Baud Rate | 1000000 | Standard for Dynamixel |
| Operating Mode | 3 | Extended Position Control |
| Torque Limit | 1000 mA | ~6 Nm max |
| Velocity Limit | 100 RPM | Adjustable |
| Temperature Limit | 70°C | Safety threshold |

### Controller Parameters

| Parameter | Value | Notes |
|-----------|-------|-------|
| Update Rate | 100 Hz | Control loop frequency |
| P Gain | 100.0 | Position proportional gain |
| I Gain | 0.0 | Keep zero for stability |
| D Gain | 10.0 | Damping |
| Command Timeout | 1.0 s | Auto-disable if no command |

---

## 🐛 Known Limitations & Future Work

### Current (POC)
- Manual position commands only (trajectory planning not yet implemented)
- Simple averaging of motor positions (not weighted by torque)
- No load balancing algorithm
- No individual motor health monitoring

### Future Enhancements
- [ ] Trajectory planning support
- [ ] Load-aware torque distribution
- [ ] Individual motor diagnostics
- [ ] Thermal management
- [ ] Fault detection (one motor fails)
- [ ] Auto-synchronization calibration
- [ ] Force feedback

---

## 📁 File Structure

```
duo_joint/
├── urdf/
│   └── duo_joint.urdf                    # ✅ Updated: ROS 2 control section
├── config/
│   ├── controllers.yaml                  # ✅ New: Motor + controller config
│   └── joint_names_duo_joint.yaml
├── launch/
│   ├── dual_motor_control.launch.py     # ✅ New: ROS 2 Humble launch
│   ├── display.launch
│   └── gazebo.launch
├── scripts/
│   ├── test_dual_motor_sync.py          # ✅ New: Test suite
│   └── monitor_dual_motors.py           # ✅ New: Real-time monitor
├── DUAL_MOTOR_POC.md                    # ✅ New: Full documentation
├── QUICK_START.md                       # ✅ New: Quick reference
├── IMPLEMENTATION_SUMMARY.md            # ✅ New: This file
├── CMakeLists.txt                       # ✅ Updated: ROS 2 Humble
├── package.xml                          # ✅ Updated: ROS 2 Humble
└── meshes/                              # (unchanged)
```

---

## 🎯 Next Steps

### Immediate (Today)
1. [ ] Verify motor IDs are correctly set (22 & 21)
2. [ ] Test with `use_mock_hardware:=true`
3. [ ] Check `/joint_states` topic
4. [ ] Test motor movement with real hardware (low torque)

### Short-term (This Week)
1. [ ] Full synchronization test with `test_dual_motor_sync.py`
2. [ ] Load capacity verification
3. [ ] Temperature monitoring during operation
4. [ ] Record performance metrics

### Medium-term (This Month)
1. [ ] Integrate into main SKUBA arm URDF
2. [ ] Add to CI/CD pipeline
3. [ ] Production testing & validation
4. [ ] Document lessons learned

---

## 📞 Support Commands

```bash
# Check ROS 2 setup
ros2 --version

# Verify package is built
ros2 pkg list | grep duo_joint

# Test launch file syntax
ros2 launch duo_joint dual_motor_control.launch.py --show-args

# View available resources
ros2 service list
ros2 action list
ros2 topic list -v
```

---

## 🎓 Learning Resources

- **ROS 2 Control:** https://control.ros.org/
- **Dynamixel Hardware Interface:** In `dynamixel_hardware_interface` package
- **ROS 2 Humble Documentation:** https://docs.ros.org/en/humble/

---

**Implementation Status:** ✅ **COMPLETE**  
**Testing Status:** 🟡 **READY FOR TESTING**  
**Production Status:** 🔴 **NOT YET**

---

*Created: 2026-10-30*  
*Version: 0.1 (POC)*  
*Author: SKUBA R&D Team*
