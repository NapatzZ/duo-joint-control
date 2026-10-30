#!/bin/bash

################################################################################
# Quick Test - Real Hardware Testing
################################################################################

SERIAL_PORT="/dev/cu.usbserial-A98FRPHD"
DOCKER_IMAGE="duo-joint-humble"

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  Dual Motor Hardware Quick Test                        ║"
echo "║  Serial Port: $SERIAL_PORT              ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Check serial port
if [ ! -e "$SERIAL_PORT" ]; then
    echo "❌ Serial port $SERIAL_PORT not found!"
    echo ""
    echo "Available serial ports:"
    ls -la /dev/cu.usbserial* 2>/dev/null || echo "  No serial ports found"
    exit 1
fi

echo "✅ Serial port found"
echo "✅ Ready to test"
echo ""
echo "🚀 Starting ROS 2 controller with real motors..."
echo "────────────────────────────────────────────────────────"
echo ""

# Run Docker with serial port
docker run -it --rm \
    --device=$SERIAL_PORT:/dev/ttyUSB0 \
    $DOCKER_IMAGE bash << 'DOCKER_BASH'

source /opt/ros/humble/setup.bash
source install/setup.bash 2>/dev/null || true

echo ""
echo "✅ ROS 2 ready"
echo "✅ Launching controller..."
echo ""

ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware=false

DOCKER_BASH

echo ""
echo "════════════════════════════════════════════════════════"
echo "Test complete"
