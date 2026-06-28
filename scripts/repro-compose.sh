#!/usr/bin/env bash
# Composition experiment: reproduce the zero-parse with bin-only and
# ascii-only streams (vs the mixed stream already tested). Same
# baud-change trigger (wrong-baud 115200 flip before each 921600
# capture). Device assumed at 921600. Captures + .timing to scratchpad.
set -u
BASE=/home/nps-gnc/data/prgs/nps-gnc/rw-vn100/test-data/zero-parse/compose
N=20

flip(){ rw-vn100 bench 1 --baud 115200 >/dev/null 2>&1; }

phase(){
  local name=$1
  local out="$BASE/$name"
  mkdir -p "$out"
  echo "=== $name: sanity (clean 921600) ==="
  rw-vn100 bench 1 --baud 921600 2>&1 | grep -E "ASCII:|Binary:"
  echo "=== $name: stress ($N baud-change opens) ==="
  local i ts
  for i in $(seq 1 "$N"); do
    flip
    ts=$(date +%H%M%S%3N)
    printf "run %2d: " "$i"
    rw-vn100 bench 1 --baud 921600 --capture "$out/cap-r${i}-${ts}.bin" 2>&1 \
      | grep -E "ASCII:|Binary:|none" | tr '\n' ' '
    echo
  done
}

echo "### configure BIN-ONLY (7-field 200Hz, ascii off)"
rw-vn100 set-ascii=off --baud 921600 >/dev/null
rw-vn100 set-bin-fields=time,ypr,quat,gyro,accel,imu,magpres --baud 921600 >/dev/null
rw-vn100 set-bin-hz=200 --baud 921600 >/dev/null
rw-vn100 set-bin=on --baud 921600 >/dev/null
phase binonly

echo "### configure ASCII-ONLY (ymr, bin off)"
rw-vn100 set-bin=off --baud 921600 >/dev/null
rw-vn100 set-ascii=ymr --baud 921600 >/dev/null
phase asciionly

echo "### restore mixed config (bin on + ascii ymr)"
rw-vn100 set-bin=on --baud 921600 >/dev/null
rw-vn100 set-ascii=ymr --baud 921600 >/dev/null
echo "done"
