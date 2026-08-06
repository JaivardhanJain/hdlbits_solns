# Exams_m2014_q4b

**HDLBits link:** https://hdlbits.01xz.net/wiki/exams/m2014_q4b
**Category:** Circuits: Sequential (Latches and Flip-flops)
**Difficulty:** ⭐⭐

## Problem summary

Implement the given schematic: a single D flip-flop on the positive edge of `clk`, with an active-high **asynchronous** reset `ar` that clears `q` immediately, without waiting for a clock edge.

## Approach

This is [[Dff8ar]] narrowed from 8 bits to 1 — same construct, same reasoning, so the interesting part isn't the code but the fact that the problem arrives as a *picture* rather than a written spec.

```verilog
always @(posedge clk, posedge ar)
    if (ar) q <= 1'b0;
    else    q <= d;
```

The three things the schematic has to tell you, and where each one lands in the code:

| What to read off the diagram | Where it shows up |
|---|---|
| Which input is the clock (triangle on the flop) | `posedge clk` in the sensitivity list |
| Whether the reset is async (a pin on the flop body) or sync (logic feeding D) | `ar` in the sensitivity list vs. only in the `if` |
| Reset polarity — bubble on the pin means active-low | `if (ar)` vs. `if (~ar)` |

Here the port comment settles the async question outright, and the reset is active-high, so it's the canonical async-clear template unchanged.

## Gotchas / things to watch for

- **The sync/async distinction is invisible in the body of the block.** `if (ar) q <= 1'b0; else q <= d;` is character-for-character what a *synchronous* reset would look like — [[Dff8r]] has exactly that body. The only thing separating the two circuits is whether `posedge ar` appears in the sensitivity list. When you're transcribing a schematic and moving fast, it's easy to write the body correctly and never revisit the sensitivity list, producing a working flip-flop with the wrong reset behaviour that passes any test not specifically probing reset-between-edges.
- **A reset pin drawn on the flop body means async; reset logic drawn in front of D means sync.** That's the visual cue these exam questions test. If the diagram shows the reset signal feeding a gate or mux whose output goes into D, it's synchronous no matter what the signal is called — and it belongs *only* in the `if`, never in the sensitivity list.
- **Check for the bubble before assuming active-high.** `ar` here is active-high, so `if (ar)` is right, but the identically-drawn circuit with an inversion bubble on the reset pin needs `always @(posedge clk, negedge ar)` **and** `if (!ar)`. Both halves have to flip together — see [[Dff8ar]], where getting only one of them is the classic bug.
- **`1'b0`, not `0`.** One bit wide, so an unsized `0` is harmless, but the habit is what matters — this is the same sized-literal discipline from [[Step One]] that made `34` silently mean `0x22` in [[Dff8p]].
- **`q` must be `reg`.** Procedurally assigned; HDLBits's bare `output q` only compiles because their grader treats it as SystemVerilog. Same note as [[Dff8ar]].

## Solution

See `exams_m2014_q4b.v`.
