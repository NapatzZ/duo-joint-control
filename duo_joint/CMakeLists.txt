cmake_minimum_required(VERSION 3.16)
project(duo_joint)

# ROS 2 Humble with ament_cmake
find_package(ament_cmake REQUIRED)

# Find dependencies
find_package(robot_state_publisher REQUIRED)
find_package(joint_trajectory_controller REQUIRED)
find_package(controller_manager REQUIRED)
find_package(sensor_msgs REQUIRED)
find_package(trajectory_msgs REQUIRED)

# Install directories
install(DIRECTORY
  config
  launch
  meshes
  urdf
  DESTINATION share/${PROJECT_NAME}
)

# Ament package setup
ament_package()
