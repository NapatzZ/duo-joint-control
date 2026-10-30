cmake_minimum_required(VERSION 3.16)
project(duo_joint)

# ROS 2 Humble with ament_cmake
find_package(ament_cmake REQUIRED)
find_package(ament_cmake_python REQUIRED)

# Find dependencies
find_package(robot_state_publisher REQUIRED)
find_package(joint_trajectory_controller REQUIRED)
find_package(controller_manager REQUIRED)
find_package(sensor_msgs REQUIRED)
find_package(trajectory_msgs REQUIRED)
find_package(rclpy REQUIRED)

# Install directories
install(DIRECTORY
  config
  launch
  meshes
  urdf
  scripts
  DESTINATION share/${PROJECT_NAME}
)

# Install Python scripts
ament_python_install_package(scripts)

# Install Python executable scripts
install(PROGRAMS
  scripts/test_dual_motor_sync.py
  scripts/monitor_dual_motors.py
  DESTINATION lib/${PROJECT_NAME}
)

# Ament package setup
ament_package()
