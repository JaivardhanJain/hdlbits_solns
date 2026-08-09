# Edgedetect2

**HDLBits link:** https://hdlbits.01xz.net/wiki/edgedetect2
**Category:** Circuits: Sequential (Latches and Flip-flops)
**Difficulty:** ⭐⭐⭐

## Problem summary

Same setup as [[Edgedetect]], but generalized: for each of 8 bits, flag *any* change between one clock cycle and the next — a fall as well as a rise — one cycle after it happens.

## Approach

[[Edgedetect]] needed AND-with-inverted-previous because it only cared about one direction (0→1). Widening the question to "did this bit change at all" is exactly what XOR answers: `a ^ b` is 1 precisely when `a` and `b` differ, regardless of which one is 0 and which is 1.

```verilog
always @ (posedge clk) begin
    d_last  <= in;
    anyedge <= in ^ d_last;
end
```

Structurally this is [[Edgedetect]] unchanged — same shadow register `d_last`, same two-line clocked block, same reasoning for why statement order inside the block doesn't matter (both non-blocking assignments read the pre-edge `d_last`) and why the result naturally lands one cycle after the transition. The only thing that changed is the single operator connecting `in` and `d_last`.

## Gotchas / things to watch for

- **`in ^ d_last` catches both directions on purpose — don't reach for `|` out of habit.** After solving [[Edgedetect]], `&` and `~` are fresh in mind, and it's tempting to bolt together `(in & ~d_last) | (~in & d_last)` (rising OR falling, spelled out explicitly) to get "any edge." That's not wrong, but it's XOR's truth table written out longhand — `a^b` already equals exactly that expression, more compactly and more directly readable as "these two differ." Recognizing XOR as "any change" (as opposed to `&`/`~` for "specifically 0→1") is the actual generalization this problem is testing, not just widening the answer.
- **`anyedge` needs `output reg`, same as `pedge` did in [[Edgedetect]].** Assigned inside a clocked always block, so it's a variable, not a net — HDLBits's bare `output [7:0] anyedge` only compiles because their grader treats the file as SystemVerilog.
- **This still only reports a difference, not which direction it went.** `anyedge[i]` being set doesn't tell you whether bit `i` rose or fell — that information exists for exactly one cycle (comparing `in[i]` to `d_last[i]` at detection time) and is gone once `anyedge` is registered. If a design needs to distinguish rising from falling later, that has to be captured separately, at the same time, not reconstructed afterward from `anyedge` alone.
- **No reset, same reasoning as [[Edgedetect]].** The port list is `clk`/`in`/`anyedge` only; `d_last` starting undefined for the first cycle is the accurate model of the spec, not a gap to fill in.

## Solution

See `edgedetect2.v`.
