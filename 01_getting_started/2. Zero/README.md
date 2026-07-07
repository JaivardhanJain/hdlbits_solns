# Zero

**HDLBits link:** https://hdlbits.01xz.net/wiki/Zero
**Category:** Getting Started
**Difficulty:** ⭐

## Problem summary

Simplest possible module: Set an output to 0.

## Approach

Just a continuous assignment (`assign`) to 1, no logic needed.

## Gotchas / things I got wrong initially

- Bare `0` vs `1'b0`: `1` is an unsized decimal literal, which Verilog treats as 32-bit by default and then truncates to fit the 1-bit output, it happens to work here only because truncating to 1 bit is trivial. `1'b0` is explicitly 1 bit wide, so there's no implicit width conversion at all. Always use size literals explicitly to match the signal width; relying on unsized literals is how width-mismatch bugs creep in once outputs are wider than 1 bit. For best practice use 1'b0 over 0.

## Solution

See `zero.v`
