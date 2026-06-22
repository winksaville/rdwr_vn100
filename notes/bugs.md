# Bugs

This file uses [Prose form](../AGENTS.md#prose-form). It lists known
defects we're aware of but haven't scheduled a fix for. Each entry
describes what goes wrong, when, and the cost of the failure.

Each bug is a `### Issue #N — <title>` subsection. The Issue # is a
permanent, monotonic id — assigned once from the allocator below,
never reused or renumbered — so the heading doubles as a stable
anchor (`#issue-N-…`) that todo / chores / commits can link to. The
title may be reworded; the `issue-N` prefix of the anchor stays put.

Next Issue #: 2

## Bugs

### Issue #1 — high-baud reconnect can wedge the VN-100 UART

A cross-process reconnect (a fresh `rdwr_vn100` invocation opening
the port) at a high baud can wedge the VN-100's UART completely:
afterward the device is silent at *every* baud, recoverable only
by a power cycle. The failure is intermittent and probabilistic
per reconnect — not a clean threshold — and the odds rise with
baud.

The locus is narrow. The **in-session** baud switch (the `baud`
command sends `VNWRG,05` and talks at the new rate on the live
connection) was clean at every baud tested. Only the
**fresh-process reopen** at the new baud wedges.

- First observation, 2026-06-26 (chained, *no* power cycle
  between switches):
    - `baud 57600` → verified; `bench --baud 57600` (fresh
      process) → clean, 40.0 Hz.
    - `--baud 57600 baud 230400` → verified (1 retry); `bench
      --baud 230400` (fresh process) → **clean, 40.0 Hz** once.
    - The very next fresh-process open at 230400 → no reply;
      `--baud 115200 get-hz` → no reply. Silent at both. Power
      cycle restored 115200 / 40 Hz.
- Controlled retest, 2026-06-26 (**fresh power cycle before each**
  baud, explicit `--baud`):
    - 57600 → switch verified (1 retry); fresh-process bench
      clean, 40.3 Hz.
    - 115200 (boots here) → fresh-process bench clean, 39.8 Hz.
    - 230400 → switch verified; fresh-process bench clean,
      40.0 Hz.
    - 921600 → switch verified; fresh-process bench → **wedged on
      the first reconnect** (no reply). Power cycle restored
      115200 / 40 Hz.
- All baud changes were volatile (no `--persist`), so every power
  cycle reverts to the flash default 115200 / 40 Hz.
- 115200 has a clean record across many reconnects. 57600 and
  230400 each survived one clean reconnect from a fresh power
  cycle — but 230400 wedged in the chained run, so a clean device
  state helps and is not a guarantee. 921600 wedged immediately.
  None of the single clean runs is a reliability proof.
- The bench link is RS-232: a Gearmo GM-FTD12-LED-C USB-C to
  RS-232 adapter (±5.7 V output, rated 300 bps–460 Kbps) into the
  VN-100's RS-232 port. 921600 is ~2× that rating. We think the
  cause is RS-232 slew-rate limiting — on the adapter's
  transceiver and on the VN-100's own onboard RS-232 transceiver,
  neither swappable — mis-framing bytes into the device at high
  baud, which its firmware reacts to by wedging. It is *not* an
  FTDI control-line transient: no handshake lines are wired. Full
  analysis: chores-01 [[1]].
- This is an RS-232-rig finding. The RPi5 flight target uses a
  direct 3.3 V TTL UART with no RS-232 transceivers in the path,
  so the wedge must be retested there before it is treated as a
  VN-100 limit. We think it may not reproduce on TTL.

**Cost / why it matters:** an intermittent *unrecoverable* failure
that passes bench testing is the worst kind for flight use — it
ships, then wedges the IMU mid-flight with no recovery but cutting
power. "Works sometimes" is not safe. Binary output already gives
200 Hz at the rock-solid 115200, so there is no reason to chase a
higher device baud.

# References

[1]: chores/chores-01.md#rs-232-link-analysis
