# Dual Motor Synchronization Test - ROS 2 Humble

Two Dynamixel MX106 motors (IDs 22 and 21) drive one joint (`dual_joint`) through ROS 2 control. This repository records an experiment on how closely the two motors stay in sync.

```
Motor 22 ┐
         ├─→ dual_joint   (mirrored: joint = 0.5·pos22 − 0.5·pos21)
Motor 21 ┘
```

## Questions

1. How far apart do the two motors get while moving?
2. Do they move at the same time?
3. How are they kept in sync, and what makes the sync better?

## Setup

- Linux machine, real motors on `/dev/ttyUSB0`, one controller container (Docker, ROS 2 Humble), controller update rate 50 Hz.
- Both motors get the same goal through the mirror matrices `1, -1` (command) and `0.5, -0.5` (state); same operating mode (3), current limit (400) and profile.
- Motion: `dual_joint` swung ±28.6° (±0.5 rad) with the commanded speed raised in 7 steps (19, 29, 38, 57, 82, 115, 164 °/s). Each step is a back-and-forth swing; the run is 49 s.
- Two settings, 3 runs each: `Profile Velocity` / `Profile Acceleration` = **40 / 20** (repo default) and **120 / 60**. The change was applied only on the test machine; the repo URDF still has 40 / 20.
- Per-motor position, velocity and current from `/dynamic_joint_states` (~60 Hz).
- **Mismatch** = `(pos22 − rest22) − (−(pos21 − rest21))`. 0 means perfectly mirrored. The zero offset is taken from the first 1.8 s at rest. One encoder tick is 0.088°.

## Results

![motor 22 vs motor 21 synchronization](docs/motor_sync.png)

Raw data: `docs/motorsync_pv{40,120}_r{1,2,3}.csv` (`t_s, ref_rad, joint_fb_rad, motor22_pos_rad, motor21_pos_rad, motor22_vel_rad_s, motor21_vel_rad_s, motor22_current, motor21_current`).

### 1. How far apart (max mismatch, mean ± SD of 3 runs)

| Commanded speed (°/s) | `Profile Velocity` 40 | `Profile Velocity` 120 |
|---|---|---|
| 19 | 0.29 ± 0.06° | 0.26 ± 0.00° |
| 38 | 0.50 ± 0.26° | 0.26 ± 0.00° |
| 57 | 0.99 ± 0.42° | 0.29 ± 0.05° |
| 82 | 1.81 ± 1.20° | 0.53 ± 0.15° |
| 115 | 0.94 ± 0.95° | 0.53 ± 0.09° |
| 164 | 1.06 ± 1.30° | 1.29 ± 1.47° |

- At rest the mismatch is ≤ 0.1° (about 1 encoder tick).
- RMS mismatch is 0.1–0.8° over the sweep.
- The mismatch comes in short bursts during acceleration and direction reversal and returns to ~0 afterwards.
- At 164 °/s the result changes a lot from run to run (SD ≈ 1.3–1.5°), so the two settings cannot be told apart there.

### 2. Simultaneity

- The cross-correlation lag between the two motors is 0 ms.
- The start-of-motion difference is about −3 to −9 ms (motor 21 slightly earlier). This is below the ~16 ms sample period, so the offset is small but not resolved.

### 3. Load sharing

- The peak current of motor 21 is usually higher than that of motor 22 (for example about 100 vs 66 at 29 °/s with `Profile Velocity` 40), so the load is shared unevenly. Current units were not converted or verified.

## How the motors are kept in step (checked in the code and config)

- Both goal positions go out in one `GroupSyncWrite` packet, so both motors receive the command at the same time.
- Both motors are read with one `GroupFastSyncRead`, so both positions come from the same bus cycle.
- Both are driven from the single `dual_joint` command through the mirror matrices, with identical settings.

## What makes the sync better

Tested:
- Raising `Profile Velocity` / `Profile Acceleration` from 40 / 20 to 120 / 60 cut the max mismatch 2–3× at 38–115 °/s (0.99° → 0.29° at 57 °/s, 1.81° → 0.53° at 82 °/s).

Not tested yet:
- Calibrate the zero offset of the two motors so the mirrored positions start exactly equal.
- Use the time-based profile (Drive Mode) so both motors take the same time to reach each goal.
- Match the position PID gains and check the mechanical coupling for backlash (the current imbalance suggests uneven load).
- Raise the update rate. The USB latency timer (16 ms) limited the controller to 50 Hz; lowering it to 1 ms should allow more.

## Limits of this test

- Samples are ~60 Hz, so timing differences below ~16 ms are not resolved.
- Only 3 runs per setting; the 164 °/s results are too variable to compare.
- `torque_state` in `/dynamixel_hardware_interface/dxl_state` read `false` for both motors during the moves; this was not checked against the torque-enable register.

## Reproduce

```bash
docker build -t duo-joint-humble -f Dockerfile.minimal .
docker run -it --rm --name duo --device=/dev/ttyUSB0:/dev/ttyUSB0 -v "$PWD":/ws -w /ws duo-joint-humble bash -c \
  'source /opt/ros/humble/setup.bash && colcon build --packages-select dynamixel_interfaces dynamixel_hardware_interface duo_joint && source install/setup.bash && ros2 launch duo_joint dual_motor_control.launch.py'
# second terminal: per-motor state while sending a JointTrajectory to /joint_trajectory_controller/joint_trajectory
docker exec -it duo bash -c 'source /opt/ros/humble/setup.bash && ros2 topic echo /dynamic_joint_states'
```

Run only one controller at a time: a second process on the same serial port freezes the feedback. Docker Desktop on macOS cannot pass through serial devices; run on Linux.
