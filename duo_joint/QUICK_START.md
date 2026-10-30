# Dual Motor POC - Quick Start Guide

**TL;DR:** Start here to get dual motors (IDs 22 & 21) running on ROS 2 Humble.

---

## 🏃 60-Second Setup

```bash
# 1. Build
cd /Users/napat/Desktop/skuba_ws/dual-joint
colcon build --packages-select duo_joint
source install/setup.bash

# 2. Launch (Terminal 1)
ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware:=false

# 3. Monitor (Terminal 2)
python3 src/duo_joint/scripts/monitor_dual_motors.py

# 4. Command (Terminal 3)
ros2 topic pub /joint_trajectory_controller/joint_trajectory \
trajectory_msgs/JointTrajectory \
"header: {stamp: now, frame_id: ''}, 
 joint_names: ['dual_joint'],
 points: [{positions: [0.5], velocities: [0.0], time_from_start: {sec: 3}}]"
```

---

## 🎮 Common Commands

### Launch & Hardware

```bash
# Real motors
ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware:=false

# Mock hardware (testing without motors)
ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware:=true

# With custom port/baud
ros2 launch duo_joint dual_motor_control.launch.py \
  port_name:=/dev/ttyUSB1 baud_rate:=115200
```

### Monitoring

```bash
# Real-time monitor (fancy)
python3 src/duo_joint/scripts/monitor_dual_motors.py

# Raw joint state
ros2 topic echo /joint_states

# Controller status
ros2 topic echo /joint_trajectory_controller/state
```

### Commands (Move Motors)

```bash
# Home (0 rad)
ros2 topic pub --once /joint_trajectory_controller/joint_trajectory \
trajectory_msgs/JointTrajectory \
"header: {stamp: now, frame_id: ''}, 
 joint_names: ['dual_joint'],
 points: [{positions: [0.0], velocities: [0.0], time_from_start: {sec: 2}}]"

# Positive (1.0 rad / ~57°)
ros2 topic pub --once /joint_trajectory_controller/joint_trajectory \
trajectory_msgs/JointTrajectory \
"header: {stamp: now, frame_id: ''}, 
 joint_names: ['dual_joint'],
 points: [{positions: [1.0], velocities: [0.0], time_from_start: {sec: 3}}]"

# Negative (-1.0 rad / ~-57°)
ros2 topic pub --once /joint_trajectory_controller/joint_trajectory \
trajectory_msgs/JointTrajectory \
"header: {stamp: now, frame_id: ''}, 
 joint_names: ['dual_joint'],
 points: [{positions: [-1.0], velocities: [0.0], time_from_start: {sec: 3}}]"
```

### Testing

```bash
# Run full test suite
python3 src/duo_joint/scripts/test_dual_motor_sync.py

# Record data
ros2 bag record /joint_states -o my_test_data

# Playback
ros2 bag play my_test_data
```

### Debugging

```bash
# List controllers
ros2 control list_controllers

# List hardware interfaces
ros2 control list_hardware_interfaces

# Check all topics
ros2 topic list -v

# View all ROS 2 nodes
ros2 node list
```

---

## 🔴 Emergency Stop

If motors are out of control:

```bash
# Option 1: Ctrl+C in launch terminal (stop all controllers)
^C

# Option 2: Disable torque on motors
# (Requires custom service, or use Dynamixel Wizard)

# Option 3: Kill the entire launch
pkill -f "ros2 launch duo_joint"
```

---

## ⚡ Hardware Verification

### Before Running

1. **Check connections:**
   ```bash
   ls -la /dev/ttyUSB*  # Should see your serial port
   ```

2. **Check motor IDs:**
   - Use Dynamixel Wizard 2 to verify IDs are 22 and 21
   - Verify baud rate is set to 1000000

3. **Check wiring:**
   - RS485 A (white) connected properly
   - RS485 B (black) connected properly
   - GND connected
   - Power connected (12V recommended for MX106)

### After Launch

1. **Check /joint_states topic:**
   ```bash
   ros2 topic echo /joint_states | head -10
   ```
   Should show `dual_joint` with position/velocity data

2. **Check for errors:**
   ```bash
   ros2 topic echo /joint_trajectory_controller/state | grep error
   ```
   Should be near zero if synchronized

---

## 📊 What's What

| File | Purpose |
|------|---------|
| `urdf/duo_joint.urdf` | Robot model with dual motor config |
| `config/controllers.yaml` | Motor params & PID gains |
| `launch/dual_motor_control.launch.py` | ROS 2 Humble launch file |
| `scripts/monitor_dual_motors.py` | Real-time monitoring tool |
| `scripts/test_dual_motor_sync.py` | Comprehensive test suite |

---

## 🎯 Success Checklist

- [ ] Motors detected by hardware interface
- [ ] `/joint_states` topic publishing
- [ ] `dual_joint` visible in joint list
- [ ] Motors move when commanded
- [ ] Both motors move together (synchronized)
- [ ] No error messages
- [ ] Motors not overheating

---

## 🆘 Common Issues & Quick Fixes

| Problem | Quick Fix |
|---------|-----------|
| `Connection timeout` | Check USB port: `ls /dev/ttyUSB*` |
| `Motor not found` | Verify ID with Dynamixel Wizard |
| `Permission denied /dev/ttyUSB0` | `sudo chmod 666 /dev/ttyUSB0` |
| `Motors move separately` | Check transmission matrix in URDF (should be `1, 1`) |
| `Joint doesn't move` | Check torque limit, try `Torque Enable = 1` |
| `Out of range error` | Limit position to ±3.14 rad (±180°) |

---

## 📚 Full Documentation

For detailed info, see:
- **DUAL_MOTOR_POC.md** - Complete documentation
- **config/controllers.yaml** - Parameter explanations
- **launch/dual_motor_control.launch.py** - Launch file comments

---

**Status:** ✅ Ready to Test  
**Last Updated:** 2026-10-30
