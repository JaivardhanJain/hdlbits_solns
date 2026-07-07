# NotGate

**HDLBits link:** https://hdlbits.01xz.net/wiki/NotGate
**Category:** Verilog Basics
**Difficulty:** ⭐

## Problem summary

Invert the input and wire it to the output.


## Approach

A continuous assignment (`assign`) from the input to the output, after adding a not ('~').

## Gotchas / things I got wrong initially
 - ~ (bitwise) vs ! (logical) NOT are interchangeable on a 1-bit signal, but not equivalent — ! reduces a multi-bit value to a single bit, ~ inverts bit-by-bit. Use ~ here since it's the one that generalizes.

## Solution

See `not_gate.v`
