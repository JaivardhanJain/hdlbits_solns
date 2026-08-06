# Dff8r

**HDLBits link:** https://hdlbits.01xz.net/wiki/dff8r
**Category:** Circuits: Sequential (Latches and Flip-flops)
**Difficulty:** ⭐⭐

## Problem summary

Designing 8 flip flops, whose ds and ps are part of the same bus that also have a synchronous reset.

## Approach

Use a always block sensitive to the positive clock edge and then use a non-blocking assignment to assign the value of d at the clock edge to p. Since p and d are vectors, they will automatically create 8 flip-flops. Add an if statement to reset p. 

## Gotchas / things to watch for
- **Make sure to use `always @(posedge clk)`.** As in [[Dff]] and [[Dff8]], `always @(*)` is for combinational logic; only an edge-triggered sensitivity list produces real flip-flop behavior.
- **Use `<=` in every branch, not just the ones that "look like" the register update.** It's easy to reach for `q <= d;` on the normal path but slip into a blocking `q = 8'b0;` on the reset path, since the reset value feels more like "setting a constant" than "updating a register." Both branches update the same register on the same clock edge, so both need `<=` — mixing assignment types across branches of the same always block is inconsistent and, in blocks more complex than a single if/else, can introduce the exact race-condition risk described in [[Dff]]. `q <= 8'b0;` and `q <= d;` in the two branches here is the corrected, consistent form.
- **Adding `reset` to the sensitivity list of the always block.** Doing this (`always @(posedge clk or posedge reset)`, or worse, `always @(*)`) would make the reset asynchronous — it could fire the moment `reset` goes high, independent of the clock edge. This problem specifically asks for a *synchronous* reset, meaning `reset` should only be checked *inside* the clocked always block (as an `if` condition), never added to the sensitivity list itself; only `posedge clk` belongs there.

## Solution

See `dff8r.v`.
