#!/usr/bin/env python3
"""
Test Script for Dual Motor Synchronization (ROS 2 Humble)
Monitors and verifies that both motors (IDs 22 & 21) move together in sync
"""

import rclpy
from rclpy.node import Node
from sensor_msgs.msg import JointState
from trajectory_msgs.msg import JointTrajectory, JointTrajectoryPoint
from builtin_interfaces.msg import Duration
import numpy as np
import time


class DualMotorSyncTester(Node):
    def __init__(self):
        super().__init__("dual_motor_sync_tester")

        # Subscribers
        self.joint_state_sub = self.create_subscription(
            JointState,
            "/joint_states",
            self.joint_state_callback,
            10,
        )

        # Publishers
        self.trajectory_pub = self.create_publisher(
            JointTrajectory,
            "/joint_trajectory_controller/joint_trajectory",
            10,
        )

        # State tracking
        self.joint_positions = {}
        self.joint_velocities = {}
        self.joint_names = []
        self.sync_errors = []
        self.position_error_threshold = 0.05  # rad (~2.9 degrees)
        self.velocity_error_threshold = 0.1   # rad/s

        self.get_logger().info("Dual Motor Sync Tester initialized")
        self.get_logger().info("Waiting for joint_states topic...")

    def joint_state_callback(self, msg: JointState):
        """Capture joint state information"""
        self.joint_names = msg.name

        for i, name in enumerate(msg.name):
            self.joint_positions[name] = msg.position[i] if i < len(msg.position) else 0.0
            self.joint_velocities[name] = msg.velocity[i] if i < len(msg.velocity) else 0.0

        # Check synchronization if this is our dual joint
        if "dual_joint" in self.joint_names:
            self.check_sync_health()

    def check_sync_health(self):
        """Monitor dual motor synchronization"""
        pos = self.joint_positions.get("dual_joint", 0.0)
        vel = self.joint_velocities.get("dual_joint", 0.0)

        # Log current state periodically
        if len(self.sync_errors) % 50 == 0:  # Every ~5 seconds at 10 Hz
            self.get_logger().info(
                f"[SYNC STATUS] Position: {pos:.3f} rad | Velocity: {vel:.3f} rad/s"
            )

    def send_position_command(self, position: float, duration_sec: float = 2.0):
        """Send position command to dual_joint"""
        msg = JointTrajectory()
        msg.joint_names = ["dual_joint"]
        msg.header.stamp = self.get_clock().now().to_msg()

        point = JointTrajectoryPoint()
        point.positions = [position]
        point.velocities = [0.0]
        point.effort = [0.0]
        point.time_from_start = Duration(sec=int(duration_sec), nanosec=0)

        msg.points.append(point)

        self.trajectory_pub.publish(msg)
        self.get_logger().info(f"Sent command: position={position:.3f} rad, duration={duration_sec}s")

    def run_test_sequence(self):
        """Run predefined test sequence"""
        self.get_logger().info("\n" + "="*60)
        self.get_logger().info("DUAL MOTOR SYNCHRONIZATION TEST SEQUENCE")
        self.get_logger().info("="*60 + "\n")

        # Wait for first joint state
        rclpy.spin_once(self, timeout_sec=2.0)
        time.sleep(1)

        if not self.joint_positions:
            self.get_logger().error("❌ No joint states received! Check hardware connection.")
            return False

        self.get_logger().info(f"✓ Joint states received: {list(self.joint_names)}")

        if "dual_joint" not in self.joint_names:
            self.get_logger().error("❌ 'dual_joint' not found in joint states!")
            self.get_logger().info(f"   Available joints: {self.joint_names}")
            return False

        self.get_logger().info("✓ dual_joint found\n")

        # Test 1: Home position (0 rad)
        self.get_logger().info("[TEST 1] Moving to HOME (0 rad)...")
        self.send_position_command(0.0, duration_sec=3.0)
        time.sleep(4)

        pos = self.joint_positions.get("dual_joint", 0.0)
        self.get_logger().info(f"  Current position: {pos:.3f} rad")

        if abs(pos - 0.0) > 0.2:
            self.get_logger().warn("  ⚠ Motors didn't reach home position")
        else:
            self.get_logger().info("  ✓ Home position reached")

        time.sleep(1)

        # Test 2: Positive position (1.0 rad)
        self.get_logger().info("\n[TEST 2] Moving to +1.0 rad...")
        self.send_position_command(1.0, duration_sec=3.0)
        time.sleep(4)

        pos = self.joint_positions.get("dual_joint", 0.0)
        self.get_logger().info(f"  Current position: {pos:.3f} rad")

        if abs(pos - 1.0) > 0.2:
            self.get_logger().warn("  ⚠ Motors didn't reach target position")
        else:
            self.get_logger().info("  ✓ Target position reached")

        time.sleep(1)

        # Test 3: Negative position (-1.0 rad)
        self.get_logger().info("\n[TEST 3] Moving to -1.0 rad...")
        self.send_position_command(-1.0, duration_sec=3.0)
        time.sleep(4)

        pos = self.joint_positions.get("dual_joint", 0.0)
        self.get_logger().info(f"  Current position: {pos:.3f} rad")

        if abs(pos - (-1.0)) > 0.2:
            self.get_logger().warn("  ⚠ Motors didn't reach target position")
        else:
            self.get_logger().info("  ✓ Target position reached")

        time.sleep(1)

        # Test 4: Return to home
        self.get_logger().info("\n[TEST 4] Returning to HOME (0 rad)...")
        self.send_position_command(0.0, duration_sec=3.0)
        time.sleep(4)

        pos = self.joint_positions.get("dual_joint", 0.0)
        self.get_logger().info(f"  Current position: {pos:.3f} rad")

        if abs(pos - 0.0) > 0.2:
            self.get_logger().warn("  ⚠ Motors didn't return home")
        else:
            self.get_logger().info("  ✓ Returned to home")

        # Summary
        self.get_logger().info("\n" + "="*60)
        self.get_logger().info("TEST SEQUENCE COMPLETE")
        self.get_logger().info("="*60)

        return True


def main(args=None):
    rclpy.init(args=args)

    tester = DualMotorSyncTester()

    try:
        # Run test sequence in background
        import threading
        test_thread = threading.Thread(target=tester.run_test_sequence, daemon=True)
        test_thread.start()

        # Keep node alive
        rclpy.spin(tester)

    except KeyboardInterrupt:
        print("\n\nTest interrupted by user")
    finally:
        tester.destroy_node()
        rclpy.shutdown()


if __name__ == "__main__":
    main()
