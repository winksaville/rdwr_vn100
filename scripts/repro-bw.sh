#!/usr/bin/env bash
# Parametrized baud-change zero-parse repro at 921600 with a
# configurable stream, for bandwidth / composition sweeps.
#
# Usage: repro-bw.sh LABEL BIN_HZ ASCII_HZ [N]
#   LABEL     output subdir under test-data/zero-parse/compose/
#   BIN_HZ    binary 7-field rate in Hz; 0 = binary off
#   ASCII_HZ  ascii VNYMR rate in Hz;  0 = ascii off
#   N         baud-change opens (default 20)
#
# Each measured open is a baud *change* (a wrong-baud 115200 open
# precedes each captured 921600 read). Captures + .timing land in the
# LABEL dir. Device is left in the configured state (each run
# reconfigures from the top). Device assumed reachable at 921600.
set -u
LABEL=${1:?need LABEL}
BIN_HZ=${2:?need BIN_HZ (0=off)}
ASCII_HZ=${3:?need ASCII_HZ (0=off)}
N=${4:-20}
OUT=/home/nps-gnc/data/prgs/nps-gnc/rw-vn100/test-data/zero-parse/compose/$LABEL
mkdir -p "$OUT"

echo "### configure: bin=${BIN_HZ}Hz ascii=${ASCII_HZ}Hz"
if [ "$BIN_HZ" -gt 0 ]; then
  rw-vn100 set-bin-fields=time,ypr,quat,gyro,accel,imu,magpres --baud 921600 >/dev/null
  rw-vn100 set-bin-hz="$BIN_HZ" --baud 921600 >/dev/null
  rw-vn100 set-bin=on --baud 921600 >/dev/null
else
  rw-vn100 set-bin=off --baud 921600 >/dev/null
fi
if [ "$ASCII_HZ" -gt 0 ]; then
  rw-vn100 set-ascii=ymr --baud 921600 >/dev/null
  rw-vn100 set-ascii-hz="$ASCII_HZ" --baud 921600 >/dev/null
else
  rw-vn100 set-ascii=off --baud 921600 >/dev/null
fi

echo "=== sanity (clean 921600) ==="
rw-vn100 bench 1 --baud 921600 2>&1 | grep -E "ASCII:|Binary:|Wire"

echo "=== stress ($N baud-change opens) ==="
fails=0
for i in $(seq 1 "$N"); do
  rw-vn100 bench 1 --baud 115200 >/dev/null 2>&1   # wrong-baud flip
  ts=$(date +%H%M%S%3N)
  printf "run %2d: " "$i"
  res=$(rw-vn100 bench 1 --baud 921600 --capture "$OUT/cap-r${i}-${ts}.bin" 2>&1)
  echo "$res" | grep -E "ASCII:|Binary:|none" | tr '\n' ' '
  if echo "$res" | grep -q "saw no ASCII messages or binary frames"; then
    fails=$((fails + 1))
  fi
  echo
done
echo "### RESULT $LABEL: $fails fails / $N opens"
