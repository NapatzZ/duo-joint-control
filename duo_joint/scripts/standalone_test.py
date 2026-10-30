#!/usr/bin/env python3
"""
Standalone Dual Motor Test - Works without ROS 2
Tests motor synchronization logic without requiring rclpy
Perfect for development and testing on macOS
"""

import time
import math
from dataclasses import dataclass
from typing import Tuple


@dataclass
class MotorState:
    """Simulated motor state"""
    id: int
    position: float = 0.0
    velocity: float = 0.0
    current: float = 0.0
    temperature: float = 25.0


class DualMotorSimulator:
    """Simulates dual motor synchronization without ROS 2"""

    def __init__(self):
        self.motor_22 = MotorState(id=22)
        self.motor_21 = MotorState(id=21)
        self.joint_command = 0.0
        self.simulation_time = 0.0

        print("\n" + "="*70)
        print("STANDALONE DUAL MOTOR SIMULATOR (No ROS 2 Required)")
        print("="*70)
        print(f"\n✅ Motor 22 (ID: 22) - Ready")
        print(f"✅ Motor 21 (ID: 21) - Ready")
        print(f"\n📊 Transmission Matrix: [1, 1]")
        print(f"   Both motors contribute equally to dual_joint")
        print("\n" + "-"*70 + "\n")

    def send_position_command(self, position: float, duration: float = 2.0):
        """Send position command to both motors"""
        self.joint_command = position

        print(f"📤 Command Sent:")
        print(f"   Target Position: {position:+.3f} rad ({position*180/math.pi:+.1f}°)")
        print(f"   Duration: {duration:.1f}s")
        print(f"   Motor 22 Target: {position:+.3f} rad")
        print(f"   Motor 21 Target: {position:+.3f} rad")

        # Simulate smooth motion
        start_time = time.time()
        steps = int(duration * 10)  # 10 updates per second

        for step in range(steps + 1):
            elapsed = time.time() - start_time
            progress = min(elapsed / duration, 1.0)

            # Smooth acceleration (ease-in-out)
            smooth_progress = progress ** 2 * (3 - 2 * progress)

            # Update motor positions
            self.motor_22.position = smooth_progress * position
            self.motor_21.position = smooth_progress * position

            # Calculate velocity
            if progress > 0 and progress < 1:
                self.motor_22.velocity = (position / duration) * (1 - abs(progress - 0.5) * 4)
                self.motor_21.velocity = (position / duration) * (1 - abs(progress - 0.5) * 4)
            else:
                self.motor_22.velocity = 0.0
                self.motor_21.velocity = 0.0

            # Simulate temperature rise during motion
            if progress > 0 and progress < 1:
                self.motor_22.temperature = 25 + 10 * abs(self.motor_22.velocity)
                self.motor_21.temperature = 25 + 10 * abs(self.motor_21.velocity)
            else:
                self.motor_22.temperature = 25.0
                self.motor_21.temperature = 25.0

            # Display status
            self._display_status(progress)

            time.sleep(0.1)

        print()

    def _display_status(self, progress: float):
        """Display current motor status"""
        # Clear line and print status
        print(f"\r   Progress: {progress*100:3.0f}% | " +
              f"Motor22: {self.motor_22.position:+.3f}rad | " +
              f"Motor21: {self.motor_21.position:+.3f}rad | " +
              f"Sync Error: {abs(self.motor_22.position - self.motor_21.position):.4f}rad" +
              f" | Temps: {self.motor_22.temperature:.1f}°C, {self.motor_21.temperature:.1f}°C",
              end="", flush=True)

    def check_synchronization(self) -> Tuple[float, bool]:
        """Check if motors are synchronized"""
        error = abs(self.motor_22.position - self.motor_21.position)
        is_synced = error < 0.05  # 0.05 rad = ~2.9 degrees tolerance
        return error, is_synced

    def check_temperature(self) -> bool:
        """Check if motors are within safe temperature range"""
        safe_22 = self.motor_22.temperature < 70
        safe_21 = self.motor_21.temperature < 70
        return safe_22 and safe_21

    def get_joint_state(self) -> dict:
        """Get simulated joint state (as would be published by ROS 2)"""
        # Averaged position from both motors
        joint_position = (self.motor_22.position + self.motor_21.position) / 2
        joint_velocity = (self.motor_22.velocity + self.motor_21.velocity) / 2

        return {
            "joint_name": "dual_joint",
            "position": joint_position,
            "velocity": joint_velocity,
            "motor_22": {
                "position": self.motor_22.position,
                "velocity": self.motor_22.velocity,
                "temperature": self.motor_22.temperature,
            },
            "motor_21": {
                "position": self.motor_21.position,
                "velocity": self.motor_21.velocity,
                "temperature": self.motor_21.temperature,
            }
        }


def run_test_sequence():
    """Run complete test sequence"""
    simulator = DualMotorSimulator()

    # Test 1: Home position
    print("🧪 TEST 1: Moving to HOME (0 rad)")
    print("-" * 70)
    simulator.send_position_command(0.0, duration=2.0)

    error, synced = simulator.check_synchronization()
    print(f"   ✓ Position: {simulator.motor_22.position:+.3f} rad")
    print(f"   ✓ Sync Error: {error:.4f} rad {'✅' if synced else '❌'}")
    print(f"   ✓ Temperature Safe: {simulator.check_temperature()}\n")
    time.sleep(1)

    # Test 2: Positive position
    print("🧪 TEST 2: Moving to +1.0 rad (57°)")
    print("-" * 70)
    simulator.send_position_command(1.0, duration=3.0)

    error, synced = simulator.check_synchronization()
    state = simulator.get_joint_state()
    print(f"   ✓ dual_joint Position: {state['position']:+.3f} rad")
    print(f"   ✓ Sync Error: {error:.4f} rad {'✅' if synced else '❌'}")
    print(f"   ✓ Temperature Safe: {simulator.check_temperature()}\n")
    time.sleep(1)

    # Test 3: Negative position
    print("🧪 TEST 3: Moving to -1.0 rad (-57°)")
    print("-" * 70)
    simulator.send_position_command(-1.0, duration=3.0)

    error, synced = simulator.check_synchronization()
    state = simulator.get_joint_state()
    print(f"   ✓ dual_joint Position: {state['position']:+.3f} rad")
    print(f"   ✓ Sync Error: {error:.4f} rad {'✅' if synced else '❌'}")
    print(f"   ✓ Temperature Safe: {simulator.check_temperature()}\n")
    time.sleep(1)

    # Test 4: Return home
    print("🧪 TEST 4: Returning to HOME (0 rad)")
    print("-" * 70)
    simulator.send_position_command(0.0, duration=2.0)

    error, synced = simulator.check_synchronization()
    state = simulator.get_joint_state()
    print(f"   ✓ dual_joint Position: {state['position']:+.3f} rad")
    print(f"   ✓ Sync Error: {error:.4f} rad {'✅' if synced else '❌'}")
    print(f"   ✓ Temperature Safe: {simulator.check_temperature()}\n")

    # Summary
    print("\n" + "="*70)
    print("✅ TEST SEQUENCE COMPLETE")
    print("="*70)
    print("\nTest Results:")
    print(f"  Motor 22 Final Position: {simulator.motor_22.position:+.3f} rad")
    print(f"  Motor 21 Final Position: {simulator.motor_21.position:+.3f} rad")
    print(f"  Synchronization Error: {error:.4f} rad")
    print(f"  Motors Synchronized: {'✅ YES' if synced else '❌ NO'}")
    print(f"  Temperatures Safe: {'✅ YES' if simulator.check_temperature() else '❌ NO'}")
    print("\n" + "="*70)


def run_interactive_test():
    """Interactive mode - send commands from command line"""
    simulator = DualMotorSimulator()

    print("\n🎮 INTERACTIVE MODE - Enter commands:")
    print("  Position value in radians (e.g., 0.5)")
    print("  Type 'quit' to exit\n")

    while True:
        try:
            cmd = input(">>> Enter position (-3.14 to 3.14): ").strip()

            if cmd.lower() == 'quit':
                print("Exiting...")
                break

            position = float(cmd)

            if -3.14 <= position <= 3.14:
                print(f"\n✅ Sending command: {position:.3f} rad\n")
                simulator.send_position_command(position, duration=2.0)

                state = simulator.get_joint_state()
                error, synced = simulator.check_synchronization()

                print(f"\n📊 Current State:")
                print(f"   dual_joint: {state['position']:+.3f} rad ({state['position']*180/math.pi:+.1f}°)")
                print(f"   Velocity: {state['velocity']:+.3f} rad/s")
                print(f"   Sync Error: {error:.4f} rad {'✅' if synced else '❌'}")
                print(f"   Motor22 Temp: {state['motor_22']['temperature']:.1f}°C")
                print(f"   Motor21 Temp: {state['motor_21']['temperature']:.1f}°C\n")
            else:
                print("❌ Value out of range. Use -3.14 to 3.14\n")

        except ValueError:
            print("❌ Invalid input. Enter a number or 'quit'\n")
        except KeyboardInterrupt:
            print("\n\nExiting...")
            break


if __name__ == "__main__":
    import sys

    if len(sys.argv) > 1 and sys.argv[1] == "--interactive":
        run_interactive_test()
    else:
        run_test_sequence()
