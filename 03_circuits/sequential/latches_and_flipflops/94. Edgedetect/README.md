# Edgedetect

**HDLBits link:** https://hdlbits.01xz.net/wiki/edgedetect
**Category:** Circuits: Sequential (Latches and Flip-flops)
**Difficulty:** ⭐⭐⭐

## Problem summary

For each of 8 independent bits, detect a 0→1 transition from one clock cycle to the next. `pedge[i]` should go high for exactly one cycle — the cycle *after* `in[i]` is seen to rise — and low otherwise.

## Approach

Detecting a transition requires comparing the current cycle to the previous one, and "previous cycle" is exactly what a register is for: a second flip-flop, `d_last`, that simply shadows `in` one cycle behind.

```verilog
always @ (posedge clk) begin
    d_last <= in;
    pedge  <= in & ~d_last;
end
```

Once `d_last` holds last cycle's `in`, a rising edge on bit `i` is precisely the condition "`in[i]` is 1 now AND `in[i]` was 0 last cycle" — bitwise AND of `in` with the bitwise NOT of `d_last`. Because both operands are already 8-bit vectors, `in & ~d_last` computes all 8 bits' edge detection in one expression, with no per-bit loop — the same "vector-width bitwise ops scale for free" property from [[Gatesv100]], just built on registered values instead of combinational ones.

### Why this naturally lands one cycle late, matching the spec

The spec says `pedge` should be set *the cycle after* the transition, and this circuit does that without any extra effort — it's a consequence of how non-blocking assignment works, not a separate design decision. On the clock edge where `in` first becomes 1, `d_last` still holds the *previous* cycle's value (0), because non-blocking assignment reads every right-hand side using pre-edge values before anything updates. So `pedge <= in & ~d_last` correctly computes "1 AND NOT 0" = detected, and that result is registered — meaning it becomes visible on `pedge` only *after* this edge, i.e. during the next cycle. The one-cycle delay the spec asks for and the one-cycle delay `<=` naturally produces are the same delay; the two are related, not just individually satisfied.

## Gotchas / things to watch for

- **Both non-blocking assignments read `d_last` before either one is applied — that's exactly what makes the order in the block not matter.** `d_last <= in;` is listed first here, but `pedge`'s calculation still uses the *old* `d_last`, not the just-scheduled new one, because non-blocking assignment always evaluates its right-hand side against pre-edge values. Writing the two lines in the opposite order produces the identical circuit. This is the same [[Dff]] rule that's been true all chapter, but it matters more concretely here than in earlier problems, because there are now two *dependent* registers being updated in the same block from data that flows between them — swap `<=` for blocking `=` and the order stops being interchangeable: `d_last = in;` executed first would overwrite `d_last` before `pedge`'s calculation ever reads it, corrupting the edge detection into "compare `in` to itself" and permanently zeroing `pedge`.
- **`d_last` has no reset, and that's correct, not an omission.** The module interface is `clk`/`in`/`pedge` only, matching the pattern from [[Exams_m2014_q4d]]: when a problem's ports don't include a reset, don't invent one. Without a defined starting state, `d_last` (and by extension `pedge`) is simply undefined for the first cycle of simulation — that's an accurate model of a real edge detector that hasn't seen its first clock edge yet, not a bug to engineer around.
- **`pedge` is a genuine registered output, not a same-cycle combinational flag.** It would be easy to instead write `assign pedge = in & ~d_last;` (dropping `pedge` from the clocked block and making it a `wire`) — that still compiles and still looks like "edge detection," but it removes the one-cycle delay the spec explicitly asks for: with a combinational `assign`, `pedge` would rise in the *same* cycle `in` rises, not the next one. The choice to register `pedge` alongside `d_last`, both driven by the same clock, is what produces the correct timing — not incidental to it.
- **A pulse only one cycle wide is easy to miss if you're only watching the waveform loosely.** Because `pedge` is high for exactly one cycle per transition and then returns low even if `in` stays at 1, a quick glance at a waveform can make it look like nothing happened if you're not looking at the right cycle. This shape — a single-cycle pulse marking a transition — is the building block for [[Edgedetect2]] and [[Edgecapture]] immediately next in the chapter, so it's worth being precise about exactly which cycle it appears on now.

## Solution

See `edgedetect.v`.
