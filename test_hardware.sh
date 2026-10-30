#!/bin/bash

################################################################################
# Dual Motor Hardware Test Script (Simplified)
# Tests motors on /dev/cu.usbserial-A98FRPHD
################################################################################

DOCKER_IMAGE="duo-joint-humble"
CONTAINER_NAME="duo-joint-hw-test"

# Auto-detect serial port (macOS or Linux)
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

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Functions
print_header() {
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"

    if ! command -v docker &> /dev/null; then
        print_error "Docker not installed"
        exit 1
    fi
    print_success "Docker installed"

    if ! docker image inspect $DOCKER_IMAGE &> /dev/null; then
        print_error "Docker image not found. Build it first:"
        echo "  docker build -t $DOCKER_IMAGE -f Dockerfile.minimal ."
        exit 1
    fi
    print_success "Docker image found"

    if [ -z "$SERIAL_PORT" ]; then
        print_error "No serial port found!"
        echo ""
        echo "  macOS ports: $(ls -1 /dev/cu.usbserial* 2>/dev/null || echo 'none')"
        echo "  Linux ports: $(ls -1 /dev/ttyUSB* 2>/dev/null || echo 'none')"
        echo "  Linux ports: $(ls -1 /dev/ttyACM* 2>/dev/null || echo 'none')"
        exit 1
    fi
    print_success "Serial port detected: $SERIAL_PORT"
}

# Show menu
show_menu() {
    print_header "Dual Motor Hardware Test Menu"
    echo ""
    echo "Select option:"
    echo "  1) Launch Controller (real hardware)"
    echo "  2) Test with Mock Hardware"
    echo "  0) Exit"
    echo ""
    read -p "Enter choice (0-2): " choice
}

# Main
main() {
    clear
    print_header "Dual Motor Hardware Test"
    echo "Serial Port: $SERIAL_PORT"
    echo "Docker Image: $DOCKER_IMAGE"
    echo ""

    check_prerequisites

    echo ""

    while true; do
        show_menu

        case $choice in
            1)
                echo ""
                print_header "Testing with REAL Hardware"
                echo ""

                # Run Docker without -it (causes TTY issues)
                docker run -i --rm --device=$SERIAL_PORT:/dev/ttyUSB0 $DOCKER_IMAGE bash << 'EOF'
source /opt/ros/humble/setup.bash

echo "🔨 Building ROS 2 package..."
cd /ws && colcon build --packages-select duo_joint 2>&1 | tail -5

source install/setup.bash

echo ""
echo "🚀 Launching ROS 2 Controller with REAL motors..."
echo ""

ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware=false
EOF

                echo ""
                ;;
            2)
                echo ""
                print_header "Testing with MOCK Hardware"
                echo ""

                # Run Docker without -it (causes TTY issues)
                docker run -i --rm $DOCKER_IMAGE bash << 'EOF'
source /opt/ros/humble/setup.bash

echo "🔨 Building ROS 2 package..."
cd /ws && colcon build --packages-select duo_joint 2>&1 | tail -5

source install/setup.bash

echo ""
echo "🚀 Launching ROS 2 Controller with MOCK motors..."
echo ""

ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware=true
EOF

                echo ""
                ;;
            0)
                print_info "Exiting..."
                exit 0
                ;;
            *)
                echo ""
                print_error "Invalid choice"
                echo ""
                ;;
        esac
    done
}

# Run
main
