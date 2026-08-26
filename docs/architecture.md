# Architecture

Small systemd-supervised components keep collection, rendering and input
separate:

1. `aster-sysinfo` publishes generic system metrics.
2. Dashboard sensors add Proxmox, network, mount and NVMe SMART state.
3. Patched `asterctl` renders the selected panel.
4. A persistent MAFP helper turns touch duration into tap/hold triggers.
5. A power-event helper opens the guarded System Actions modal.

Fast host metrics are published roughly once per second. Event-like Proxmox
inventory is refreshed asynchronously every five seconds so slow `qm`, `pct`
or `pvesm` calls cannot stall CPU, memory and network updates. NVMe SMART data
keeps its slower cache interval. The external rotating disk retains its guarded
policy: SMART is refreshed only after block activity proves the disk is already
awake.

Top-level panels are Health, Compute, optional GPU, Storage, Network and
Services. Child panels use `Parent > Child` names, allowing navigation to
discover them without hard-coded panel counts. Missing removable disks are
omitted, not reported as failed placeholders.

Internal NVMe slots are enumerated at runtime. The configured system NVMe stays
`INT 1`; an additional NVMe becomes `INT 2` and gets independent SMART,
temperature, capacity and detail-panel data. Device paths are resolved before
comparison so an external USB4 NVMe is never mistaken for an internal slot.

The GPU panel follows the same model: `lab_gpu_present` activates both its
overview and detail panels only when `nvidia-smi` can communicate with a GPU.
DCGM service state, boot-local Xid events and temperature feed the shared
Compute health state. A disconnected optional GPU is omitted rather than shown
as an empty placeholder.

Each storage detail panel prioritizes temperature, real used space, SMART,
wear, data written, power-on time, available/total filesystem capacity and
media errors. Unsafe-shutdown counts remain available through raw SMART tools
but do not consume a primary LCD card.

Health states are rendered compactly as `✓ OK`, amber `● Warn`, and red `Err`
with a slowly blinking dot. Unavailable data is never silently presented as a
healthy zero. Error conditions include SMART/media failures, unsafe temperature
and required-service failure.
