# Dff8

**HDLBits link:** https://hdlbits.01xz.net/wiki/dff8
**Category:** Circuits: Sequential (Latches and Flip-flops)
**Difficulty:** ⭐⭐

## Problem summary

Designing 8 flip flops, whose ds and ps are part of the same bus.

## Approach

Use a always block sensitive to the positive clock edge and then use a non-blocking assignment to assign the value of d at the clock edge to p. 

## Gotchas / things to watch for
- **Make sure to use `always @(posedge clk)`.** As in [[Dff]], `always @(*)` belongs to combinational logic; an edge-triggered sensitivity list is what makes this a register instead of a latch or a wire.
- **Use the non-blocking assignment `<=`, not `=`.** As in [[Dff]], `<=` is what correctly models 8 independent flip-flops all sampling `d` on the same clock edge and updating together. With 8 bits in one vector assignment (`q <= d;`), this is still a single non-blocking assignment — it's not 8 separate statements, so there's no risk of only some bits updating "before" others; the whole vector is scheduled as one update.
- **Assuming `q <= d;` on vectors needs to be unrolled bit by bit.** It doesn't — a single non-blocking assignment between two same-width vectors assigns every bit in one statement, which is what actually produces 8 DFFs when synthesized (each output bit gets its own flip-flop, but the Verilog describing it stays one line). Writing a `for` loop or 8 separate `q[i] <= d[i];` lines would be functionally identical but unnecessarily verbose for this problem.

## Solution

See `dff8.v`.
