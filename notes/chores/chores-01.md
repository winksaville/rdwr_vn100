# Chores-01

Chores-XX files use [Prose form](../../AGENTS.md#prose-form). They
contain discussions and notes on various chores in github compatible
markdown. There is also a [todo.md](../todo.md) file that tracks
tasks and in general there should be a chore section for each task
with the why and how this task will be completed.

## docs: completed dummy chore (0.1.0)

A completed dummy chore description.

## chore: dummy chore (TBD)

A dummy chore description.

## docs: RS-232 wedge root cause + RPi5 TTL port plan

Commits:

Benching the VN-100 baud climb wedged the device at 921600 —
silent at every baud until a power cycle. The investigation traced
the cause to the bench rig's RS-232 link, not the VN-100, and the
real flight target (RPi5) drives the IMU over a clean 3.3 V TTL
link — which reframes both the bug and the next step.

- Bug recorded as [[1]] (bugs.md Issue #1) with the full baud
  matrix and the recovery (power-cycle the VN-100 only; the FTDI
  adapter stays enumerated, which is what proved the wedge is in
  the device, not the host or adapter).
- The VN-100 firmware supports 921600 (Reg 5) and the in-session
  baud switch read cleanly at 921600 — so the device UART can do
  it. Only the cross-process *reopen* over RS-232 wedges. Cause:
  see [RS-232 link analysis](#rs-232-link-analysis).
- Next step: port `rdwr_vn100` to the RPi5 and re-run the baud
  climb on the TTL UART to test whether the wedge is RS-232-only.
  The tool is already portable (pure Rust + `serialport` crate);
  only the default `--port` (`/dev/ttyUSB0`, `main.rs:463`) is
  bench-specific. On the Pi the line is `/dev/ttyAMA0` (or the
  `/dev/serial0` symlink) — reachable today via `--port`. RPi5
  UART setup: free the line from the serial console
  (`enable_uart=1`, disable the console getty); 3.3 V logic only.
- On the Pi the IMU read path lives in existing Python (primary
  app `../fc/src/fc.py`, plus `../fc/scripts`). We do *not* need
  to port the whole app now, and we do *not* need the VectorNav
  C++ SDK — `rdwr_vn100` already replaces it by talking the
  VN-100 binary protocol directly in Rust. Near-term scope is
  just that: read the VN-100 from Rust over the Pi's TTL link.
  How it then feeds `fc.py` (IPC or a PyO3 module) is a later
  boundary question; a full Rust rewrite (the `fcbr` direction)
  is wanted eventually, not now.

### RS-232 link analysis

The bench adapter is a Gearmo GM-FTD12-LED-C — a USB-C to true
RS-232 adapter (±5.7 V output, rated 300 bps–460 Kbps on the spec
sheet; the "1 Mbps" is marketing-page only). The data lines are
RS-232 levels, so there is no TTL logic-level mismatch.

- Wiring: the VN-100 is on its RS-232 port (data crossed,
  adapter 2/3 ↔ VN-100 3/2), powered from a separate 5 V bench
  supply, common ground, no handshake lines.
- 921600 is ~2× the adapter's 460 Kbps rating. We think RS-232
  slew-rate limiting — on the adapter's transceiver *and* the
  VN-100's own onboard RS-232 transceiver, neither swappable —
  rounds the ±V waveform enough at 921600 (1.08 µs/bit) on the
  hand-made, unterminated cable to mis-frame bytes into the
  VN-100. Its firmware reacts to malformed framing by wedging.
- 57600 / 115200 / 230400 sit within the rating and reconnect
  cleanly; 921600 is 2/2 wedged. 230400 wedged once in a chained
  run with no power cycle between switches, so it is borderline.
- The RPi5 flight target avoids all of this: a direct 3.3 V TTL
  UART has no RS-232 transceivers in the path. We think the wedge
  will not reproduce on TTL; the port-to-Pi step is how we find
  out. Independent of that, binary output at 115200 already
  delivers 200 Hz, so high baud is not required for the flight
  goal — it is headroom, not a blocker.


# References

[1]: /notes/bugs.md#issue-1--high-baud-reconnect-can-wedge-the-vn-100-uart

