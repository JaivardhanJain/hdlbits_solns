# Exams_m2014_q4c

**HDLBits link:** https://hdlbits.01xz.net/wiki/exams/m2014_q4c
**Category:** Circuits: Sequential (Latches and Flip-flops)
**Difficulty:** ⭐⭐

## Problem summary

Implement the given schematic: a single D flip-flop on the positive edge of `clk` with an active-high **synchronous** reset `r`, which clears `q` only on a clock edge.

## Approach

The deliberate pairing with [[Exams_m2014_q4b]] is the whole point of this problem — the two questions are the same circuit apart from reset timing, and the code differs by exactly one thing:

```verilog
// q4b — asynchronous
always @(posedge clk, posedge ar)
    if (ar) q <= 1'b0;
    else    q <= d;

// q4c — synchronous  (this problem)
always @(posedge clk)
    if (r)  q <= 1'b0;
    else    q <= d;
```

The bodies are identical. `posedge ar` in the sensitivity list is the entire difference. With `r` absent from the sensitivity list, the block only ever runs on a clock edge, so `r` can do nothing between edges — which is what "synchronous" means. Same rule as [[Dff8r]], now at one bit.

## Gotchas / things to watch for

- **Solving q4b first makes the copy-paste mistake more likely, not less.** These two arrive back to back, and the natural move is to duplicate the previous answer and rename `ar` to `r`. Rename the signal but leave the sensitivity list alone and you've built q4b again with new labels — a flip-flop that resets the instant `r` rises. It simulates, it passes casual testing, and nothing in the body looks wrong. Whenever two problems differ only in reset timing, the sensitivity list is the line to check first, not last.
- **A synchronous reset is just data.** It's worth seeing what this actually synthesizes to: `r` isn't special hardware at all, it's a mux in front of the D pin selecting between `d` and constant 0. That's why it stays out of the sensitivity list — the flop has one and only one trigger, the clock, and everything else is combinational logic feeding D. Once you see it that way, "should this signal go in the sensitivity list?" reduces to "does this signal reach a dedicated pin on the flop, or does it reach D?" (The reverse case, and the hardware cost of a genuinely non-zero reset value, is covered in [[Dff8p]].)
- **Synchronous reset needs a running clock.** A design that's synchronously reset can't be cleared while the clock is stopped or not yet stable — at power-up, if the PLL hasn't locked, a sync reset does nothing at all. That's the practical argument for asynchronous reset assertion, and the counterweight to the metastability concern raised in [[Dff8ar]]. Neither choice is free; real designs usually assert asynchronously and release synchronously to get both.
- **Sync reset is friendlier to timing and to test.** Because reset is ordinary data, it's covered by normal setup/hold analysis with no special constraints, it can't glitch the flop between edges, and it filters narrow noise pulses on the reset line automatically (a spike that doesn't span a clock edge is simply never seen). Those are the reasons a lot of FPGA style guides default to synchronous reset unless there's a specific need for async.
- **`1'b0` over `0`, and `q` must be `reg`.** Same two notes as [[Exams_m2014_q4b]].

## Solution

See `exams_m2014_q4c.v`.
