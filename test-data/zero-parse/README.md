# zero-parse reproduction

Evidence and a repro script for the passive-`bench` **zero-parse** —
a full byte read off the wire that parses into zero messages/frames
(`ASCII: none / Binary: none`). Root-cause analysis:
[chores-01](../../notes/chores/chores-01.md) "Zero-parse root cause:
PL011 baud-change open". Tracked as Todo #1.

A fresh open whose baud differs from the previous open intermittently
corrupts the read in two modes: the new divisor never applies (stale,
undersampled garbage), or — framing intact and the byte clock right —
bit 6 (B6) flips on scattered bytes so every CRC fails (bits are
numbered 0..7 LSB-first, so B6 is the seventh). We think both are a
marginal high-baud open. The B6 flip follows a precise rule: b6 flips
to 1 iff bit b5 = 1 (see chores-01), and is uniform across the stream
— not boundary- or timing-correlated.

## `repro.sh`

Self-configuring: puts the device on 921600 + a heavy 7-field binary
+ YMR stream, sanity-checks a clean read, then alternates a
wrong-baud `--baud 115200` open before each `--baud 921600` read, so
every measured open is a baud *change*. ~20% fail. See its header
for usage and device prep.

## Captures

Raw `bench --capture` dumps — the bytes the scanner saw. Diff a
`*-fail` against its `*-before` / `*-after` (or the clean
`../both-streams.bin`, same 7-field + YMR config).

- `misframe-{before,fail,after}.bin` — B6-flip mode ("misframe" is a
  misnomer — framing is intact): the `-fail` is ~26.9 KB with all
  frames present but bit 6 flipped on scattered bytes, so every CRC
  fails (full ~269 kbit/s, none parsed). The before/after parse
  clean.
- `stale-{before,fail,after}.bin` — stale-divisor mode: the `-fail`
  is ~2.2 KB, undersampled garbage (~24 kbit/s); before/after clean.
- `cold-misframe-{1,2}.bin` — the two failures from the cold-start
  reproduction below.
- `timing-run-2/{t1,t2}-{before,fail,after}.bin` (+ `.bin.timing`) —
  two B6-flip triplets captured with the per-read timing sidecar.
  Each `t?-fail` is bracketed by a clean `-before` and `-after`. The
  `.timing` files (per-read `t_ns,offset`) show the flip is uniform
  and *not* timing/boundary-correlated.
- `compose/{mixed-50pct,binonly-95pct,binonly-48pct}/` — bandwidth
  sweep evidence (fail/clean pairs + `.timing`): the zero-parse fail
  rate scales with link utilization (chores-01 bandwidth section).
  Reproduce with `scripts/repro-bw.sh`.

## Reproductions

- **Warm** (continuously-powered device), `repro.sh` alternating
  `--baud`: 4/20 failed — 2 misframe, 2 stale (the triplets above).
- **Cold** (VN-100 power-cycled to flash defaults), `repro.sh`
  defaults (`START_BAUD=115200`): 2/20 failed (both B6-flip,
  `cold-misframe-{1,2}.bin`). Confirms it is not session state. A
  config-phase `$VNERR 0x05` (not enough parameters) also appeared.
  We think the same corruption can garble an *outgoing* command (TX
  side), not just passive reads — unconfirmed.
- **Timing** (warm, new build with the `.timing` sidecar),
  `repro.sh <out> 20 921600` ×2: failed 1/20 then 2/20. The two
  cleanly-bracketed fails are `timing-run-2/`. Across three fails
  (these two plus an earlier one) the b6-flip rate is ~30–34% on
  b5=1 bytes, uniform over the stream, with identical idle-before for
  flipped vs non-flipped frames — so it is not boundary/timing-driven.
