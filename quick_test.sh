#!/bin/bash

################################################################################
# Quick Test Script - Start testing in 30 seconds
# For real hardware on /dev/cu.usbserial-A98FRPHD
################################################################################

SERIAL_PORT="/dev/cu.usbserial-A98FRPHD"
DOCKER_IMAGE="duo-joint-humble"

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         Dual Motor Hardware Quick Test                        ║"
echo "║                                                                ║"
echo "║  Serial Port: $SERIAL_PORT              ║"
echo "║  Docker Image: $DOCKER_IMAGE                   ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check if Docker image exists
if ! docker image inspect $DOCKER_IMAGE &> /dev/null; then
    echo "🔨 Building Docker image (5-10 minutes)..."
    docker build -t $DOCKER_IMAGE .
    echo "✅ Docker image built"
    echo ""
fi

# Check serial port
if [ ! -e "$SERIAL_PORT" ]; then
    echo "❌ Serial port $SERIAL_PORT not found!"
    echo ""
    echo "Available serial ports:"
    ls -la /dev/cu.usbserial* 2>/dev/null || echo "  No serial ports found"
    exit 1
fi

echo "✅ Serial port found: $SERIAL_PORT"
echo "✅ Ready to start testing"
echo ""
echo "🚀 Starting ROS 2 controller with real motors..."
echo "   (This window will show controller logs)"
echo ""
echo "────────────────────────────────────────────────────────────────"
echo ""

# Run Docker with serial port
docker run -it --rm \
    --name duo-joint-hw-test \
    --device=$SERIAL_PORT:/dev/ttyUSB0 \
    $DOCKER_IMAGE bash << 'DOCKER_BASH'

source /opt/ros/humble/setup.bash
source install/setup.bash

echo ""
echo "✅ ROS 2 environment ready"
echo "✅ Launching dual motor controller..."
echo ""

ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware=false

DOCKER_BASH

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "Test complete"
