# Dual Motor Joint Control - ROS 2 Humble

Synchronized dual Dynamixel motors (MX106) on a single joint using ROS 2 Humble and Docker.

## Hardware Setup

```
Motor 22 (MX106) ┐
                  ├─→ dual_joint (synchronized)
Motor 21 (MX106) ┘
```

**Performance:**
- Single Motor: 6 Nm
- Dual Motors: ~12 Nm (2×)

---

## Quick Start (Linux with USB adapter)

```bash
docker build -t duo-joint-humble -f Dockerfile.minimal .
./quick_test.sh        # builds, launches, prints controller + motor state
```

Torque is off by default. Set `Torque Enable` to `1` in `duo_joint/urdf/duo_joint.urdf` to move.
Docker Desktop on macOS cannot pass through serial devices; run on Linux.

---

## Files

- `Dockerfile` - Full ROS 2 desktop
- `Dockerfile.minimal` - Faster build
- `docker-compose.yml` - Container management
- `quick_test.sh` - Build, launch and status check
- `duo_joint/` - ROS 2 package

---

**Status:** ✅ Ready for hardware testing

**GitHub:** https://github.com/NapatzZ/duo-joint-control
