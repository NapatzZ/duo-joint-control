#!/usr/bin/env python3
"""
Real-time Dual Motor Monitoring (ROS 2 Humble)
Displays live position, velocity, and synchronization status of dual motors
"""

import rclpy
from rclpy.node import Node
from sensor_msgs.msg import JointState
import sys


class DualMotorMonitor(Node):
    def __init__(self):
        super().__init__("dual_motor_monitor")

        self.joint_state_sub = self.create_subscription(
            JointState,
            "/joint_states",
            self.joint_state_callback,
            10,
        )

        self.last_position = None
        self.last_velocity = None
        self.update_count = 0

        print("\n" + "="*70)
        print("DUAL MOTOR REAL-TIME MONITOR (ROS 2 Humble)")
        print("="*70)
        print("Monitoring: Motor 22 (ID 22) + Motor 21 (ID 21) → dual_joint")
        print("-"*70 + "\n")

    def joint_state_callback(self, msg: JointState):
        """Display joint state information"""
        try:
            if "dual_joint" not in msg.name:
                return

            idx = msg.name.index("dual_joint")
            pos = msg.position[idx] if idx < len(msg.position) else 0.0
            vel = msg.velocity[idx] if idx < len(msg.velocity) else 0.0

            self.update_count += 1

            # Display every 10 updates (~1 second at 10 Hz)
            if self.update_count % 10 == 0:
                self.display_status(pos, vel)

            self.last_position = pos
            self.last_velocity = vel

        except Exception as e:
            self.get_logger().error(f"Error processing joint state: {e}")

    def display_status(self, position: float, velocity: float):
        """Display formatted status"""
        # Convert to degrees for readability
        pos_deg = position * 180.0 / 3.14159

        # Status bar
        bar_width = 40
        bar_pos = max(0, min(bar_width, int((position + 3.14159) / 6.28318 * bar_width)))
        bar = "█" * bar_pos + "░" * (bar_width - bar_pos)

        # Color based on velocity
        if abs(velocity) > 1.0:
            vel_status = "🔴 MOVING"
        elif abs(velocity) > 0.1:
            vel_status = "🟡 SETTLING"
        else:
            vel_status = "🟢 IDLE"

        # Display
        timestamp = self.get_clock().now().to_msg()
        print(f"[{timestamp.sec}.{timestamp.nanosec:09d}]")
        print(f"  Position: {position:+7.3f} rad ({pos_deg:+7.1f}°)  [{bar}]")
        print(f"  Velocity: {velocity:+7.3f} rad/s  {vel_status}")
        print("-"*70)


def main(args=None):
    rclpy.init(args=args)

    monitor = DualMotorMonitor()

    print("Press Ctrl+C to exit\n")

    try:
        rclpy.spin(monitor)
    except KeyboardInterrupt:
        print("\n\n" + "="*70)
        print("Monitor stopped")
        print("="*70)
    finally:
        monitor.destroy_node()
        rclpy.shutdown()


if __name__ == "__main__":
    main()
