# Test record

## Dynamic sensor refresh — passed

- Date: 2026-08-26
- Host: AOOSTAR GEM12+ Pro reference system

Verified that an atomic sensor-file update produces a different rendered frame
while `asterctl` remains running. On the live installation, CPU usage, CPU
frequency, memory and low-volume network traffic changed between samples;
Proxmox inventory remained correct and refreshed independently. Both dashboard
services remained active with zero restarts and no warning-level journal
entries. The external rotating disk continued to report `SLEEP`; its guarded
SMART policy was not changed.

The Health Services card reports the dynamic combined VM/container inventory.
Its health state separately checks four permanent PVE services plus six
permanent Home-Lab services. The boot-only `aoostar-startup-status` oneshot is
deliberately excluded from that core-service inventory.

## Clean build — passed

- Date: 2026-08-05
- Host: AOOSTAR GEM12+ Pro reference system
- OS: Proxmox VE 9.2.2 / Debian 13
- Kernel: `7.0.2-6-pve`
- Source directory: newly created, separate from installed source trees

Verified sequence:

1. cloned pinned `aoostar-rs` commit;
2. checked and applied consolidated patch;
3. compiled `asterctl` and `aster-sysinfo` in release mode;
4. cloned pinned libfprint commit;
5. checked and applied touch-only patch;
6. configured and compiled an isolated `mafpmoc` libfprint build;
7. staged libfprint under `dist/rootfs/opt/libfprint-mafp`;
8. compiled gesture, calibration and power-button helpers;
9. packaged dashboard, runtime scripts, units and configuration examples;
10. validated expected artifacts, JSON and shell syntax;
11. rendered the Health panel in simulation from anonymous fixture values.

The build did not install files, modify services or use installed binaries as
build artifacts.

## Existing hardware integration — passed

The same source changes are active on the reference system and have been tested
with the physical LCD, persistent fingerprint touch input, adaptive Storage
layout, native USB4/NVMe SMART data and guarded Power menu.

The orchestrated reboot and shutdown paths were also tested on hardware. They
stopped one VM and two containers, synchronized storage, performed the requested
power action, displayed startup readiness after firmware handoff, and restored
all dashboard/input services after boot.

## Scope

Passing on the reference system does not establish compatibility with other
Linux distributions, kernels, AOOSTAR revisions or fingerprint-reader firmware.
