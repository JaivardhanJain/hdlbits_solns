# Vectorgates

**HDLBits link:** https://hdlbits.01xz.net/wiki/Vectorgates
**Category:** Verilog Vectors
**Difficulty:** ⭐

## Problem summary

Using vector part-select, bit-wise and logical operators to manipulate inputs.


## Approach

Use continuous assigns and vector part-select syntax along with bit-wise or logical operators depending on the outputs.

## Gotchas / things I got wrong initially
 - You can assign to a part-select on the left-hand side, and you don't need to drive the whole vector in one statement. `out_not[2:0] = ~a;` and `out_not[5:3] = ~b;` are two separate assigns to non-overlapping bits of the same vector — that's legal, since neither statement drives a bit the other one drives.
 - A bitwise operation between two N-bit vectors replicates the operation for each bit of the vector and produces a N-bit output, while a logical operation treats the entire vector as a boolean value (true = non-zero, false = zero) and produces a 1-bit output.

## Solution

See `vectorgates.v`
