#!/bin/bash

################################################################################
# Quick Test - Real Hardware Testing
################################################################################

DOCKER_IMAGE="duo-joint-humble"

# Auto-detect serial port
detect_serial_port() {
    # Try macOS first
    if ls /dev/cu.usbserial* 2>/dev/null | head -1 | grep -q .; then
        ls /dev/cu.usbserial* 2>/dev/null | head -1
        return 0
    fi

    # Try Linux ttyUSB
    if ls /dev/ttyUSB* 2>/dev/null | head -1 | grep -q .; then
        ls /dev/ttyUSB* 2>/dev/null | head -1
        return 0
    fi

    # Try other common names
    if ls /dev/ttyACM* 2>/dev/null | head -1 | grep -q .; then
        ls /dev/ttyACM* 2>/dev/null | head -1
        return 0
    fi

    return 1
}

SERIAL_PORT=$(detect_serial_port)

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  Dual Motor Hardware Quick Test                        ║"
if [ -n "$SERIAL_PORT" ]; then
    echo "║  Serial Port: $SERIAL_PORT"
else
    echo "║  Serial Port: Not found"
fi
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Check serial port
if [ -z "$SERIAL_PORT" ]; then
    echo "❌ No serial port found!"
    echo ""
    echo "Available ports:"
    echo "  macOS: $(ls -1 /dev/cu.usbserial* 2>/dev/null || echo 'none')"
    echo "  Linux: $(ls -1 /dev/ttyUSB* 2>/dev/null || echo 'none')"
    echo "  Linux: $(ls -1 /dev/ttyACM* 2>/dev/null || echo 'none')"
    exit 1
fi

echo "✅ Serial port found"
echo "✅ Ready to test"
echo ""
echo "🚀 Starting ROS 2 controller with real motors..."
echo "────────────────────────────────────────────────────────"
echo ""

# Run Docker with serial port (no -it to avoid TTY issues)
docker run -i --rm \
    --device=$SERIAL_PORT:/dev/ttyUSB0 \
    $DOCKER_IMAGE bash << 'DOCKER_BASH'

source /opt/ros/humble/setup.bash

echo "🔨 Building ROS 2 package..."
cd /ws && colcon build --packages-select duo_joint 2>&1 | tail -5

source install/setup.bash

echo ""
echo "✅ ROS 2 ready"
echo "✅ Launching controller..."
echo ""

ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware=false

DOCKER_BASH

echo ""
echo "════════════════════════════════════════════════════════"
echo "Test complete"
