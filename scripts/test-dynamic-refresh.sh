#!/usr/bin/env bash
set -euo pipefail

root_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
dist_dir=${HOME_LAB_DIST_DIR:-$root_dir/dist}
asterctl=${1:-$dist_dir/bin/asterctl}
config=${2:-$dist_dir/share/home-lab/dashboard.json}

work_dir=$(mktemp -d)
renderer_pid=""
cleanup() {
    if [ -n "$renderer_pid" ] && kill -0 "$renderer_pid" 2>/dev/null; then
        kill "$renderer_pid" 2>/dev/null || true
        wait "$renderer_pid" 2>/dev/null || true
    fi
    rm -rf -- "$work_dir"
}
trap cleanup EXIT

mkdir -p "$work_dir/sensors" "$work_dir/render"
cp "$root_dir/tests/fixtures/sensors/demo.txt" "$work_dir/sensors/demo.txt"

cd "$work_dir/render"
"$asterctl" --simulate --save \
    --config "$config" \
    --config-dir "$dist_dir/share/home-lab" \
    --font-dir /usr/share/fonts/truetype/dejavu \
    --sensor-path "$work_dir/sensors" >/dev/null 2>&1 &
renderer_pid=$!

deadline=$((SECONDS+8))
while [ "$(find out -type f -name '*.png' 2>/dev/null | wc -l)" -lt 2 ]; do
    [ "$SECONDS" -lt "$deadline" ] || {
        echo "Dynamic refresh test timed out waiting for initial frames." >&2
        exit 1
    }
    sleep 0.2
done

before_count=$(find out -type f -name '*.png' | wc -l)
before_frame=$(find out -type f -name '*.png' | sort | tail -n1)
before_hash=$(sha256sum "$before_frame" | awk '{print $1}')

sed 's/CPU 51°C · GPU 48°C/CPU 77°C · GPU 48°C/' \
    "$work_dir/sensors/demo.txt" > "$work_dir/sensors/demo.txt.tmp"
mv "$work_dir/sensors/demo.txt.tmp" "$work_dir/sensors/demo.txt"

deadline=$((SECONDS+8))
while [ "$(find out -type f -name '*.png' | wc -l)" -le "$before_count" ]; do
    [ "$SECONDS" -lt "$deadline" ] || {
        echo "Dynamic refresh test timed out waiting for a changed frame." >&2
        exit 1
    }
    sleep 0.2
done

sleep 1.2
after_frame=$(find out -type f -name '*.png' | sort | tail -n1)
after_hash=$(sha256sum "$after_frame" | awk '{print $1}')
[ "$before_hash" != "$after_hash" ] || {
    echo "Sensor data changed but the rendered frame did not." >&2
    exit 1
}

echo "Dynamic sensor refresh test passed."
