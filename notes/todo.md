# Todo

This file uses [Prose form](../AGENTS.md#prose-form). It
contains near term tasks with a short description and
uses links or reference links for more details.

## In Progress

When a `## Todo` item is picked up, its text moves here: the
problem overview and its list of things to do. That is followed
by the "plan" — a bulleted list of the development "ladder":
   - 0.xx.y-0 blah (done)
   - 0.xx.y-1 blah blah (current)
   - 0.xx.y-2 blah blah blah
   - 0.xx.y close-out and validation

**fix: bench silences async before binary config (+ -V flag)**

`bench --bin` rejects a binary config with `$VNERR` 0x0C at a low
baud even when the binary stream fits, because it writes reg 75
while ASCII async (reg 7) is still on, so the device's fit check
sees the combined load. Silence ASCII async first. Also add a `-V`
version flag and print the version as the first line of a bench.

   - 0.2.1 fix bench async order; add -V flag + version line in
     bench; edition 2024

## Todo

 Entries are in **strict priority rank** — #1 highest,
 descending. Reprioritize by moving an entry, then
 `vc-x1 fix-todo --no-dry-run notes/todo.md` to renumber.
 The numbers are positional rank, not stable IDs — to refer
 to a Todo, name it by its **title** (a greppable mention;
 a numbered list item has no anchor to link to), not its
 number. Long-tail entries
 live in [todo-backlog.md](todo-backlog.md). Use the
 [Prose Form in AGENTS.md](../AGENTS.md#prose-form); deeper
 detail goes in `notes/chores/chores-NN.md` design
 subsections (link via `[N]` ref).

## Done

Completed tasks are moved from `## Todo` to here, `## Done`, as they are completed
and older `## Done` sections are moved to [done.md](done.md) to keep this file small.

- feat: default RPi5 UART, fix binary port on TTL [[1]],[[2]]

# References

[1]: chores/chores-01.md#vn-100-register-75-serial-port-numbering-on-ttl
[2]: chores/chores-01.md#fix-binary-output-targets-the-wrong-vn-100-serial-port-on-ttl
