# Dff

**HDLBits link:** https://hdlbits.01xz.net/wiki/dff
**Category:** Circuits: Sequential (Latches and Flip-flops)
**Difficulty:** ⭐⭐

## Problem summary

Designing a basic flip flop.

## Approach

Use a always block sensitive to the positive clock edge and then use a non-blocking assignment to assign the value of d at the clock edge to p. 

## Gotchas / things to watch for
- **Make sure to use `always @(posedge clk)`.** `always @(*)` is for combinational logic that reacts to any input change; a flip-flop only updates on the clock edge, so the sensitivity list has to be `posedge clk` (or `negedge clk`), not a wildcard.
- **Use the non-blocking assignment `<=`, not `=`.** Blocking assignments (`=`) execute immediately and in program order within the always block, as if this were ordinary sequential code — fine for combinational logic, but wrong for modeling a flip-flop's behavior. Non-blocking assignments (`<=`) all schedule their updates to happen simultaneously at the end of the current time step, which is what actually models real flip-flop hardware: every DFF samples its input at the same clock edge and updates together. Using `=` here happens to produce the same simulated waveform for this one single-DFF circuit, but the moment there's more than one edge-triggered always block or a chain of registers reading each other, blocking assignments can produce simulation results that depend on the (unspecified) order the simulator happens to evaluate always blocks in — a race condition that non-blocking assignments are specifically designed to avoid.

## Solution

See `dff.v`.
