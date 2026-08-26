#!/usr/bin/env bash
set -euo pipefail

root_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
dist_dir=${HOME_LAB_DIST_DIR:-$root_dir/dist}

required=(
    bin/asterctl bin/aster-sysinfo bin/mafp-next-panel \
    bin/aoostar-power-transition bin/aoostar-startup-status
    bin/mafp-calibrate bin/aoostar-power-button
    bin/aoostar-lab-sensors bin/aoostar-health-monitor
    share/home-lab/dashboard.json
    rootfs/opt/libfprint-mafp/lib/libfprint-2.so.2
)
for path in "${required[@]}"; do
    [ -e "$dist_dir/$path" ] || {
        echo "Missing build artifact: $path" >&2
        exit 1
    }
done

python3 -m json.tool "$dist_dir/share/home-lab/dashboard.json" >/dev/null
bash -n "$dist_dir/bin/aoostar-lab-sensors"
bash -n "$dist_dir/bin/aoostar-health-monitor"
bash -n "$dist_dir/bin/aoostar-power-transition"
bash -n "$dist_dir/bin/aoostar-startup-status"
"$dist_dir/bin/asterctl" --version
"$dist_dir/bin/aster-sysinfo" --version

capture_dir=$dist_dir/simulation
mkdir -p "$capture_dir"
cd "$capture_dir"
timeout 3s "$dist_dir/bin/asterctl" --simulate --save \
    --config "$dist_dir/share/home-lab/dashboard.json" \
    --config-dir "$dist_dir/share/home-lab" \
    --font-dir /usr/share/fonts/truetype/dejavu \
    --sensor-path "$root_dir/tests/fixtures/sensors" || status=$?
if [ "${status:-0}" -ne 0 ] && [ "${status:-0}" -ne 124 ]; then
    exit "$status"
fi
find "$capture_dir/out" -type f -name '*.png' -print -quit | grep -q .
"$root_dir/scripts/test-dynamic-refresh.sh" \
    "$dist_dir/bin/asterctl" "$dist_dir/share/home-lab/dashboard.json"
echo "Distribution smoke test passed."
