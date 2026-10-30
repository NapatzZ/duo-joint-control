#!/bin/bash

################################################################################
# Dual Motor Hardware Test Script
# Tests motors on /dev/cu.usbserial-A98FRPHD
# Usage: ./test_hardware.sh [mock|real]
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SERIAL_PORT="/dev/cu.usbserial-A98FRPHD"
DOCKER_IMAGE="duo-joint-humble"
CONTAINER_NAME="duo-joint-test-$$"  # Unique name per run
MODE="${1:-real}"  # Default to real hardware

################################################################################
# Functions
################################################################################

print_header() {
    echo -e "${BLUE}===============================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"

    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker not installed. Install Docker Desktop for macOS"
        exit 1
    fi
    print_success "Docker installed"

    # Check if image exists
    if ! docker image inspect $DOCKER_IMAGE &> /dev/null; then
        print_warning "Docker image '$DOCKER_IMAGE' not found"
        print_info "Building Docker image (this may take 5-10 minutes)..."
        docker build -t $DOCKER_IMAGE .
        print_success "Docker image built"
    else
        print_success "Docker image found"
    fi

    # Check serial port (only for real hardware)
    if [ "$MODE" = "real" ]; then
        if [ ! -e "$SERIAL_PORT" ]; then
            print_error "Serial port $SERIAL_PORT not found!"
            print_warning "Available serial ports:"
            ls -la /dev/cu.usbserial* 2>/dev/null || echo "  No serial ports found"
            exit 1
        fi
        print_success "Serial port detected: $SERIAL_PORT"

        # Check if port is accessible
        if ! [ -r "$SERIAL_PORT" ] || ! [ -w "$SERIAL_PORT" ]; then
            print_error "No permission to access $SERIAL_PORT"
            print_info "Try: sudo chmod 666 $SERIAL_PORT"
            exit 1
        fi
        print_success "Serial port is readable/writable"
    else
        print_info "Running in MOCK MODE (no hardware required)"
    fi
}

# Build Docker command
build_docker_cmd() {
    local docker_cmd="docker run -it --name $CONTAINER_NAME"

    if [ "$MODE" = "real" ]; then
        docker_cmd="$docker_cmd --device=$SERIAL_PORT:/dev/ttyUSB0"
    fi

    docker_cmd="$docker_cmd $DOCKER_IMAGE bash"
    echo "$docker_cmd"
}

# Start container and launch ROS 2
start_ros2_launch() {
    print_header "Starting ROS 2 Controller"

    local docker_cmd=$(build_docker_cmd)
    local use_mock="true"

    if [ "$MODE" = "real" ]; then
        use_mock="false"
        print_info "Launching with REAL HARDWARE"
    else
        print_info "Launching with MOCK HARDWARE"
    fi

    # Run in container
    eval "$docker_cmd" << 'DOCKER_BASH'
source /opt/ros/humble/setup.bash
source install/setup.bash
echo "Starting ROS 2 controller..."
ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware=$use_mock
DOCKER_BASH
}

# Monitor joint states
monitor_joint_states() {
    print_header "Monitoring Joint States"

    sleep 2  # Wait for container to be ready

    print_info "Displaying /joint_states topic..."
    print_warning "Press Ctrl+C to stop monitoring"
    echo ""

    docker exec -it $CONTAINER_NAME bash << 'DOCKER_BASH'
source /opt/ros/humble/setup.bash
source install/setup.bash
ros2 topic echo /joint_states
DOCKER_BASH
}

# Send test commands
send_test_commands() {
    print_header "Sending Test Commands"

    local targets=(0.0 1.0 -1.0 0.5 -0.5 0.0)
    local durations=(2 3 3 2 2 2)

    for i in "${!targets[@]}"; do
        local target=${targets[$i]}
        local duration=${durations[$i]}

        print_info "Command $((i+1)): Moving to ${target} rad (${duration}s)"

        docker exec $CONTAINER_NAME bash << DOCKER_BASH
source /opt/ros/humble/setup.bash
source install/setup.bash
ros2 topic pub --once /joint_trajectory_controller/joint_trajectory \
trajectory_msgs/JointTrajectory \
"header: {stamp: now, frame_id: ''},
 joint_names: ['dual_joint'],
 points: [{positions: [$target], velocities: [0.0], time_from_start: {sec: $duration}}]"
DOCKER_BASH

        sleep $((duration + 1))
    done

    print_success "Test sequence complete"
}

# Interactive command mode
interactive_mode() {
    print_header "Interactive Mode - Send Custom Commands"

    print_warning "Enter positions in radians (-3.14 to 3.14)"
    print_warning "Type 'quit' to exit"
    echo ""

    while true; do
        read -p ">>> Enter position (-3.14 to 3.14): " input

        if [ "$input" = "quit" ]; then
            break
        fi

        # Validate input is a number
        if ! [[ "$input" =~ ^-?[0-9]+\.?[0-9]*$ ]]; then
            print_error "Invalid input. Enter a number like 0.5 or -1.0"
            continue
        fi

        # Check range
        if (( $(echo "$input < -3.14 || $input > 3.14" | bc -l) )); then
            print_error "Out of range. Use -3.14 to 3.14"
            continue
        fi

        print_info "Sending command: $input rad"

        docker exec $CONTAINER_NAME bash << DOCKER_BASH
source /opt/ros/humble/setup.bash
source install/setup.bash
ros2 topic pub --once /joint_trajectory_controller/joint_trajectory \
trajectory_msgs/JointTrajectory \
"header: {stamp: now, frame_id: ''},
 joint_names: ['dual_joint'],
 points: [{positions: [$input], velocities: [0.0], time_from_start: {sec: 2}}]"
DOCKER_BASH

        print_success "Command sent. Waiting 3 seconds..."
        sleep 3
    done
}

# Main menu
show_menu() {
    print_header "Dual Motor Hardware Test Menu"

    echo "Select test option:"
    echo "  1) Launch ROS 2 Controller (runs in background)"
    echo "  2) Monitor Joint States (real-time)"
    echo "  3) Run Automated Test Sequence"
    echo "  4) Interactive Mode (send custom commands)"
    echo "  5) Full Test (1 + 2 + 3)"
    echo "  6) Clean up (remove container)"
    echo "  0) Exit"
    echo ""
    read -p "Enter choice (0-6): " choice
}

# Cleanup
cleanup() {
    print_warning "Cleaning up..."
    docker stop $CONTAINER_NAME 2>/dev/null || true
    docker rm $CONTAINER_NAME 2>/dev/null || true
    print_success "Cleanup complete"
}

# Trap cleanup on exit
trap cleanup EXIT

################################################################################
# Main Script
################################################################################

main() {
    clear
    print_header "Dual Motor Hardware Test Script"
    echo "Serial Port: $SERIAL_PORT"
    echo "Mode: $MODE"
    echo "Docker Image: $DOCKER_IMAGE"
    echo ""

    # Check prerequisites
    check_prerequisites

    echo ""

    # Menu loop
    while true; do
        show_menu

        case $choice in
            1)
                echo ""
                print_header "Starting ROS 2 in background"

                local docker_cmd=$(build_docker_cmd)
                local use_mock="true"
                [ "$MODE" = "real" ] && use_mock="false"

                # Start in background
                eval "$docker_cmd" << DOCKER_BASH &
source /opt/ros/humble/setup.bash
source install/setup.bash
ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware=$use_mock
DOCKER_BASH

                CONTAINER_PID=$!
                sleep 3

                if docker ps | grep -q $CONTAINER_NAME; then
                    print_success "ROS 2 controller started in container: $CONTAINER_NAME"
                    print_info "Container will keep running. Use 'docker stop $CONTAINER_NAME' to stop"
                else
                    print_error "Failed to start container"
                fi
                echo ""
                ;;
            2)
                echo ""
                if ! docker ps | grep -q $CONTAINER_NAME; then
                    print_error "Container not running. Start with option 1 first"
                else
                    monitor_joint_states
                fi
                echo ""
                ;;
            3)
                echo ""
                if ! docker ps | grep -q $CONTAINER_NAME; then
                    print_error "Container not running. Start with option 1 first"
                else
                    send_test_commands
                fi
                echo ""
                ;;
            4)
                echo ""
                if ! docker ps | grep -q $CONTAINER_NAME; then
                    print_error "Container not running. Start with option 1 first"
                else
                    interactive_mode
                fi
                echo ""
                ;;
            5)
                echo ""
                print_header "Running Full Test Suite"

                # Build and start container
                local docker_cmd=$(build_docker_cmd)
                local use_mock="true"
                [ "$MODE" = "real" ] && use_mock="false"

                eval "$docker_cmd" << DOCKER_BASH &
source /opt/ros/humble/setup.bash
source install/setup.bash
ros2 launch duo_joint dual_motor_control.launch.py use_mock_hardware=$use_mock
DOCKER_BASH

                sleep 3

                # Run tests
                send_test_commands

                print_success "Full test suite complete"
                echo ""
                ;;
            6)
                echo ""
                cleanup
                echo ""
                ;;
            0)
                print_info "Exiting..."
                exit 0
                ;;
            *)
                print_error "Invalid choice. Try again"
                echo ""
                ;;
        esac
    done
}

# Run main function
main
