#!/usr/bin/env bash
# ASCII-only @ 200 Hz (~26% link) — matched-bandwidth vs bin-only@200Hz
# (24%), opposite composition. Same baud-change trigger. Restores mixed.
set -u
OUT=/home/nps-gnc/data/prgs/nps-gnc/rw-vn100/test-data/zero-parse/compose/asciionly-200hz
N=20
mkdir -p "$OUT"
echo "### configure ASCII-ONLY @ 200Hz"
rw-vn100 set-bin=off --baud 921600 >/dev/null
rw-vn100 set-ascii=ymr --baud 921600 >/dev/null
rw-vn100 set-ascii-hz=200 --baud 921600 >/dev/null
echo "=== sanity ==="
rw-vn100 bench 1 --baud 921600 2>&1 | grep -E "ASCII:|Binary:|Wire"
echo "=== stress ($N baud-change opens) ==="
for i in $(seq 1 "$N"); do
  rw-vn100 bench 1 --baud 115200 >/dev/null 2>&1
  ts=$(date +%H%M%S%3N)
  printf "run %2d: " "$i"
  rw-vn100 bench 1 --baud 921600 --capture "$OUT/cap-r${i}-${ts}.bin" 2>&1 \
    | grep -E "ASCII:|Binary:|none" | tr '\n' ' '
  echo
done
echo "### restore mixed (bin on, ascii ymr @ 40Hz)"
rw-vn100 set-ascii-hz=40 --baud 921600 >/dev/null
rw-vn100 set-bin=on --baud 921600 >/dev/null
rw-vn100 set-ascii=ymr --baud 921600 >/dev/null
echo done
