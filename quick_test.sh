#!/bin/bash
# Build and launch the dual motor controller in Docker, then print status.
# Usage: ./quick_test.sh [serial_port]   (default: auto-detect)
IMAGE="duo-joint-humble"
PORT="${1:-$(ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null | head -1)}"

[ -z "$PORT" ] && { echo "No serial port found (/dev/ttyUSB* or /dev/ttyACM*)"; exit 1; }
echo "Using $PORT"

docker run --rm --device="$PORT":/dev/ttyUSB0 -v "$PWD":/ws -w /ws "$IMAGE" bash -c '
source /opt/ros/humble/setup.bash
colcon build --packages-select dynamixel_interfaces dynamixel_hardware_interface duo_joint 2>&1 | tail -3
source install/setup.bash
ros2 launch duo_joint dual_motor_control.launch.py > /tmp/launch.log 2>&1 &
sleep 12
ros2 control list_controllers
timeout 5 ros2 topic echo --once /dynamixel_hardware_interface/dxl_state
timeout 5 ros2 topic echo --once /joint_states
'
