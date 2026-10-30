#!/usr/bin/env python3
"""
ROS 2 Humble Launch File for Dual Motor Control on Single Joint
Launches the hardware interface and controller manager for synchronized dual motors
"""

from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, RegisterEventHandler
from launch.event_handlers import OnProcessExit
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node


def generate_launch_description():
    # Declare arguments
    use_mock_hardware = LaunchConfiguration("use_mock_hardware", default="false")
    port_name = LaunchConfiguration("port_name", default="/dev/ttyUSB0")
    baud_rate = LaunchConfiguration("baud_rate", default="1000000")

    # Load the URDF
    urdf_file = "/Users/napat/Desktop/skuba_ws/dual-joint/duo_joint/urdf/duo_joint.urdf"
    with open(urdf_file, "r") as f:
        robot_description = f.read()

    # Node: Robot State Publisher
    robot_state_pub = Node(
        package="robot_state_publisher",
        executable="robot_state_publisher",
        output="screen",
        parameters=[{"robot_description": robot_description}],
    )

    # Node: Controller Manager (ROS 2 Control)
    controller_manager = Node(
        package="controller_manager",
        executable="ros2_control_node",
        parameters=[
            {
                "robot_description": robot_description,
                "use_sim_time": False,
            }
        ],
        output="screen",
    )

    # Node: Spawn controller after manager starts
    spawn_controller = Node(
        package="controller_manager",
        executable="spawner",
        arguments=["joint_trajectory_controller"],
        output="screen",
    )

    # Register event handler to spawn controller when manager is ready
    register_event = RegisterEventHandler(
        event_handler=OnProcessExit(
            target_action=controller_manager,
            on_exit=[spawn_controller],
        )
    )

    return LaunchDescription(
        [
            DeclareLaunchArgument(
                "use_mock_hardware",
                default_value="false",
                description="Use mock hardware instead of real Dynamixel motors",
            ),
            DeclareLaunchArgument(
                "port_name",
                default_value="/dev/ttyUSB0",
                description="Serial port for Dynamixel motors",
            ),
            DeclareLaunchArgument(
                "baud_rate",
                default_value="1000000",
                description="Baud rate for serial communication",
            ),
            robot_state_pub,
            controller_manager,
            register_event,
        ]
    )
