# Mux2to1v

**HDLBits link:** https://hdlbits.01xz.net/wiki/Mux2to1v
**Category:** Circuits / Combinational Logic / Multiplexers
**Difficulty:** ⭐⭐

## Problem summary

Same spec as [Mux2to1](../61.%20Mux2to1/README.md), widened to 100-bit buses: `out = a` when `sel = 0`, `out = b` when `sel = 1`, with `a`, `b`, `out` all `[99:0]` and `sel` still a single bit.

## Approach

`assign out = sel ? b : a;` — the ternary form from Mux2to1 carries over completely unchanged, because the ternary operator selects one whole operand or the other rather than combining them bit by bit. It doesn't care that `a`/`b`/`out` are vectors and `sel` is a scalar; it just evaluates the condition once and passes the chosen bus straight through.

## Gotchas / things I got wrong initially

- **Why the AND/OR gate formula from Mux2to1 breaks here.** `(sel & b) | (~sel & a)` worked at 1 bit, but with `sel` a 1-bit value and `b` a 100-bit vector, Verilog first has to make the operand widths match for the bitwise `&`, and it does that by *zero-extending* the narrower operand, not by replicating it across every bit. So `sel & b` really computes `(100'b0 with sel in bit 0) & b`, which ANDs only `b[0]` with `sel` and forces `b[1]` through `b[99]` to 0 regardless of `sel`'s value — same story for `~sel & a`. The result is nowhere close to a mux; it's mostly zero with a stray bit 0 left over. This is the same implicit-width-extension mechanism flagged for literals back at the `1` vs `1'b1` gotcha — it applies just as much to a control signal used in a vector expression as to a numeric literal. The fix, if you wanted to keep the gate-level form, is to explicitly replicate the select bit to the bus width: `{100{sel}} & b | {100{~sel}} & a`. The ternary form sidesteps the whole issue, which is exactly why the hint recommends it once vectors are involved.
- **Flipping the branches.** Same trap as the scalar version — `sel ? a : b` silently swaps which bus is chosen for which `sel` value. Worth reading back against the spec ("sel=0 chooses a") every time rather than trusting a quick glance.
- **Building this with `always @(*)` and a `case`/`if` that doesn't cover every `sel` value for every bit.** Any path through the always block that leaves part of `out` unassigned for some input combination gets synthesized as a latch on those bits, not a mux. The single continuous assignment here never has that gap.

## Solution

See `mux2to1v.v`
