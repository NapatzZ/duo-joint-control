# Dual Motor Synchronized Joint - POC (Proof of Concept)

**Objective:** Synchronize two MX106 Dynamixel motors (IDs 22 & 21) on a single joint to increase load capacity.

**Setup:** ROS 2 Humble + Dynamixel Hardware Interface

---

## 📋 System Overview

### Hardware Configuration

```
┌─────────────────────────────────────────┐
│      Dynamixel RS485 Bus                │
│  /dev/ttyUSB0 @ 1000000 baud            │
│                                         │
│  Motor 22 (MX106) ┐                    │
│                   ├─→ dual_joint       │
│  Motor 21 (MX106) ┘                    │
└─────────────────────────────────────────┘
```

### Transmission Matrix

```
Joints (1)  × Transmissions (2)

       Motor_22  Motor_21
Joint     1         1         ← Both motors equally contribute
```

**Meaning:** When `dual_joint` receives position command P:
- Motor 22 receives command P
- Motor 21 receives command P
- Both move together to double the torque

---

## 🚀 Quick Start (ROS 2 Humble)

### 1. Prerequisites

```bash
# Install ROS 2 Humble
sudo apt install ros-humble-desktop

# Required packages
sudo apt install ros-humble-controller-manager \
                 ros-humble-joint-trajectory-controller \
                 ros-humble-robot-state-publisher
```

### 2. Build the Package

```bash
cd /Users/napat/Desktop/skuba_ws/dual-joint
colcon build --packages-select duo_joint
source install/setup.bash
```

### 3. Launch Hardware Interface

```bash
# With real motors
ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware:=false

# Or with mock hardware (for testing without motors)
ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware:=true
```

### 4. Monitor Joint State

In another terminal:

```bash
# Simple monitoring
ros2 topic echo /joint_states

# Or use the monitoring script
python3 src/duo_joint/scripts/monitor_dual_motors.py
```

### 5. Send Position Commands

```bash
# Move to 0 rad (home)
ros2 topic pub --once /joint_trajectory_controller/joint_trajectory \
trajectory_msgs/JointTrajectory \
"header: {stamp: now, frame_id: ''}, 
 joint_names: ['dual_joint'],
 points: [{positions: [0.0], velocities: [0.0], time_from_start: {sec: 2}}]"

# Move to 1.0 rad
ros2 topic pub --once /joint_trajectory_controller/joint_trajectory \
trajectory_msgs/JointTrajectory \
"header: {stamp: now, frame_id: ''}, 
 joint_names: ['dual_joint'],
 points: [{positions: [1.0], velocities: [0.0], time_from_start: {sec: 2}}]"
```

---

## 🧪 Testing & Verification

### Test 1: Check Joint States (Mock Hardware)

```bash
# Terminal 1
ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware:=true

# Terminal 2
ros2 topic echo /joint_states
```

Expected output:
```
header:
  stamp:
    sec: 1699123456
    nanosec: 123456789
  frame_id: ''
name: ['dual_joint']
position: [0.0]
velocity: [0.0]
effort: []
```

### Test 2: Manual Synchronization Test (Real Hardware)

```bash
# Terminal 1: Launch
ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware:=false

# Terminal 2: Monitor
python3 src/duo_joint/scripts/monitor_dual_motors.py

# Terminal 3: Send commands
ros2 topic pub /joint_trajectory_controller/joint_trajectory \
trajectory_msgs/JointTrajectory \
"header: {stamp: now, frame_id: ''}, 
 joint_names: ['dual_joint'],
 points: [{positions: [0.5], velocities: [0.0], time_from_start: {sec: 3}}]"
```

**Verify:**
- ✅ Both motors move together (synchronized)
- ✅ Position feedback is smooth
- ✅ No error messages in controller output
- ✅ Motor temps stay < 60°C

### Test 3: Automated Synchronization Test

```bash
# Run the comprehensive test suite
python3 src/duo_joint/scripts/test_dual_motor_sync.py
```

This will:
1. ✓ Verify dual_joint is available
2. ✓ Move to home (0 rad)
3. ✓ Move to +1.0 rad
4. ✓ Move to -1.0 rad
5. ✓ Return to home
6. ✓ Monitor synchronization error

---

## ⚙️ Configuration

### Motor Parameters (`config/controllers.yaml`)

```yaml
motor_22:
  id: 22
  torque_limit: 1000  # mA (increase for higher load)
  velocity_limit: 100  # RPM
  temperature_limit: 70  # °C

motor_21:
  id: 21
  torque_limit: 1000
  velocity_limit: 100
  temperature_limit: 70
```

**Adjust:**
- `torque_limit`: Higher = more force but more heat
- `velocity_limit`: Lower = slower but more stable
- `temperature_limit`: Safety threshold before shutdown

### Controller Gains (`config/controllers.yaml`)

```yaml
gains:
  dual_joint:
    p: 100.0  # Proportional - increase for faster response
    i: 0.0    # Integral - careful with this
    d: 10.0   # Derivative - damping
```

**Tuning:**
- Increase `p` if joint is sluggish
- Increase `d` if overshooting
- Keep `i` = 0 for most cases

---

## 🔧 Troubleshooting

### Issue: Motors don't move

**Diagnostics:**
```bash
# Check if motors are detected
ros2 topic echo /joint_states

# Check controller status
ros2 control list_controllers

# Check for errors
ros2 topic echo /joint_trajectory_controller/state
```

**Fix:**
- Verify serial port: `ls -la /dev/ttyUSB*`
- Check motor IDs: Use Dynamixel Wizard 2
- Check cable connections
- Verify baud rate (should be 1000000)

### Issue: Motors move separately (not synchronized)

**Diagnostics:**
```bash
# Compare motor positions via diagnostic info
ros2 topic echo /diagnostics
```

**Fix:**
- Check transmission matrix in URDF (should be `1, 1`)
- Check motor calibration offsets
- Verify mechanical coupling
- Check for mechanical friction

### Issue: Motor overheating

**Diagnostics:**
```bash
# Monitor motor temperatures (if available)
ros2 topic echo /motor_diagnostics
```

**Fix:**
- Reduce `torque_limit` in config
- Reduce `velocity_limit`
- Add cooling (fan, heat sink)
- Reduce duty cycle (rest periods)

### Issue: Serial connection timeout

**Fix:**
```bash
# Check USB connection
lsusb

# Reset USB device
sudo systemctl restart systemd-udevd

# Change port permissions
sudo chmod 666 /dev/ttyUSB0
```

---

## 📊 Performance Metrics

### Expected Results

| Metric | Single Motor | Dual Motors | Improvement |
|--------|--------------|-------------|------------|
| Max Torque | 6 Nm | ~12 Nm | 2× |
| Max Load | 5 kg | ~10 kg | 2× |
| Speed | 60 RPM | 60 RPM | Same |
| Heat | Lower | Higher | ~1.5× |

### Monitoring

```bash
# Watch joint state in real-time
watch -n 0.1 'ros2 topic echo /joint_states | head -20'

# Log performance data
ros2 bag record /joint_states /joint_trajectory_controller/state -o dual_motor_log
```

---

## 📁 Project Structure

```
duo_joint/
├── urdf/
│   └── duo_joint.urdf                    # URDF with dual motor config
├── config/
│   ├── controllers.yaml                  # Controller + motor params
│   └── joint_names_duo_joint.yaml       # Joint naming (legacy)
├── launch/
│   ├── dual_motor_control.launch.py     # Main launch file (Humble)
│   ├── display.launch                   # RViz display
│   └── gazebo.launch                    # Gazebo simulation
├── scripts/
│   ├── test_dual_motor_sync.py          # Comprehensive test suite
│   ├── monitor_dual_motors.py           # Real-time monitoring
│   └── sync_calibration.py              # (TODO) Auto-sync calibration
├── DUAL_MOTOR_POC.md                    # This file
├── CMakeLists.txt
└── package.xml
```

---

## 🎯 POC Checklist

### Hardware Setup
- [ ] Mount second motor mechanically
- [ ] Connect to RS485 bus
- [ ] Set unique ID (22, 21)
- [ ] Test motors independently

### Software Setup
- [ ] Update URDF with ros2_control section
- [ ] Update transmission matrices
- [ ] Create launch files (Humble-compatible)
- [ ] Create configuration files

### Testing
- [ ] Test with mock hardware
- [ ] Verify /joint_states topic
- [ ] Test real motor movement
- [ ] Verify synchronization
- [ ] Monitor temperatures
- [ ] Load capacity test

### Documentation
- [ ] Document motor IDs and wiring
- [ ] Document calibration offsets
- [ ] Document any mechanical issues
- [ ] Record performance metrics

### Sign-Off
- [ ] POC report written
- [ ] Hardware remains stable
- [ ] Ready for production (or iterate)

---

## 📞 Support

### Common Commands

```bash
# List all active controllers
ros2 control list_controllers

# List hardware resources
ros2 control list_hardware_interfaces

# Inspect joint trajectory controller
ros2 param list /joint_trajectory_controller

# Record all joint data
ros2 bag record /joint_states -o dual_motor_data

# Play back recording
ros2 bag play dual_motor_data
```

### Debug Information

```bash
# Check ROS 2 Humble version
ros2 --version

# Check controller manager status
ros2 service call /controller_manager/list_controllers std_srvs/srv/Trigger

# List all topics
ros2 topic list -v
```

---

## 🔬 Next Steps (After POC)

1. **Synchronization Tuning**
   - Auto-calibrate position offsets
   - Tune PID gains per motor
   - Test under varying loads

2. **Production Integration**
   - Merge into main URDF
   - Add to CI/CD pipeline
   - Create production launch files

3. **Advanced Features**
   - Load balancing (distribute torque equally)
   - Fault detection (one motor fails)
   - Thermal management
   - Predictive maintenance

---

**Last Updated:** 2026-10-30  
**Version:** 0.1 (POC)  
**Status:** Ready for Testing
