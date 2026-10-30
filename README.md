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

## Quick Start

### Build Docker Image

```bash
# Fast build (5-10 minutes)
docker build -t duo-joint-humble -f Dockerfile.minimal .

# Or full desktop (15-20 minutes)
docker build -t duo-joint-humble .
```

### Test with Hardware

```bash
# Quick test
./quick_test.sh

# Full interactive menu
./test_hardware.sh
```

### Commands

**Option 1: Auto test**
```bash
./test_hardware.sh
# Select: 5 (Full Test)
```

**Option 2: Interactive**
```bash
./test_hardware.sh
# Select: 4 (Interactive Mode)
# Enter positions: 0.5, -1.0, etc.
```

---

## Files

- `Dockerfile` - Full ROS 2 desktop
- `Dockerfile.minimal` - Faster build
- `docker-compose.yml` - Container management
- `test_hardware.sh` - Test script with menu
- `quick_test.sh` - Quick 30-second test
- `duo_joint/` - ROS 2 package

---

**Status:** ✅ Ready for hardware testing

**GitHub:** https://github.com/NapatzZ/duo-joint-control
