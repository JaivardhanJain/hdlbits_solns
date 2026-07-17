# Vector4

**HDLBits link:** https://hdlbits.01xz.net/wiki/Vector4
**Category:** Verilog Vectors
**Difficulty:** ⭐

## Problem summary

Given an 8-bit input vector, sign extend it to a 32-bit vector.


## Approach

Use the replication operator.

## Gotchas / things I got wrong initially
 - The replication syntax is `{num{vector}}` — two sets of braces, both required: the inner one wraps the pattern being repeated, the outer one is a concatenation containing that repetition (often alongside other stuff, like `{ {24{in[7]}}, in }` here). Dropping either pair of braces is a syntax error.
 - `num` must be a constant, not a signal — Verilog has to know the replicated width at elaboration time, the same reason a `for` loop gets unrolled at compile time rather than iterated at runtime. You can't replicate by a variable amount; that needs a `parameter`/`localparam` or a different construct entirely.
 - Sign-extension specifically means replicating the *sign bit* (the MSB, `in[7]` here), not bit 0 and not a hardcoded `1'b0`. Replicating the wrong bit compiles fine and even looks right for positive numbers, but silently breaks for negative ones — zero-extension and sign-extension only agree when the sign bit happens to be 0.
 - Widths still have to add up: 24 replicated bits + the original 8-bit `in` = 32 bits, matching `out` exactly. Same width-matching principle as every vector problem so far — get the replication count wrong and you're back to implicit truncation/extension covering for the mistake instead of a compile error.

## Solution

See `vector4.v`
