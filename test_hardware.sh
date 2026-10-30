#!/bin/bash

################################################################################
# Dual Motor Hardware Test Script (Simplified)
# Tests motors on /dev/cu.usbserial-A98FRPHD
################################################################################

SERIAL_PORT="/dev/cu.usbserial-A98FRPHD"
DOCKER_IMAGE="duo-joint-humble"
CONTAINER_NAME="duo-joint-hw-test"

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

    if [ ! -e "$SERIAL_PORT" ]; then
        print_error "Serial port $SERIAL_PORT not found"
        echo "  Available ports:"
        ls /dev/cu.usbserial* 2>/dev/null || echo "  None found"
        exit 1
    fi
    print_success "Serial port detected: $SERIAL_PORT"
}

# Build Docker command
build_docker_cmd() {
    echo "docker run -it --rm --name $CONTAINER_NAME --device=$SERIAL_PORT:/dev/ttyUSB0 $DOCKER_IMAGE"
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

                docker_cmd=$(build_docker_cmd)

                eval "$docker_cmd" << 'DOCKER_BASH'
source /opt/ros/humble/setup.bash
source install/setup.bash 2>/dev/null || true

echo ""
echo "🚀 Launching ROS 2 Controller with REAL motors..."
echo ""

ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware=false

DOCKER_BASH

                echo ""
                ;;
            2)
                echo ""
                print_header "Testing with MOCK Hardware"
                echo ""

                docker_cmd="docker run -it --rm --name $CONTAINER_NAME $DOCKER_IMAGE"

                eval "$docker_cmd" << 'DOCKER_BASH'
source /opt/ros/humble/setup.bash
source install/setup.bash 2>/dev/null || true

echo ""
echo "🚀 Launching ROS 2 Controller with MOCK motors..."
echo ""

ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware=true

DOCKER_BASH

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
