# Popcount3

**HDLBits link:** https://hdlbits.01xz.net/wiki/Popcount3
**Category:** Circuit from description
**Difficulty:** ⭐⭐

## Problem summary

Given a 3-bit input vector, output a 2-bit count of how many of the input bits are 1 (a value from 0 to 3).

## Approach

- Build the 8-row truth table for the 3-bit input (`000`–`111`) and derive a separate sum-of-products expression for each output bit, `out[0]` and `out[1]`, then combine the minterms with `&`/`|`/`~`.
- Worth noticing after the fact: `out[0]` works out to the XOR of the three input bits, and `out[1]` works out to their majority function — that's exactly the sum and carry-out of a full adder. Same problem, different name, and it resurfaces directly when you get to the half/full adder problems.

## Gotchas / things I got wrong initially
- Deriving an 8-row truth table by hand is fine at 3 inputs but doesn't scale — this same "population count" problem shows up again later (`popcount255`) with far too many inputs to enumerate minterms for by hand; that version needs a for-loop/accumulator instead. Worth remembering this SOP approach is a 3-bit special case, not the general technique.
- Hand-deriving two separate SOP expressions from an 8-row table is easy to get subtly wrong — dropping a minterm or assigning it to the wrong output bit. Worth checking each term against the truth table row by row rather than trusting the algebra by eye.
- The simpler one-liner `assign out = in[0] + in[1] + in[2];` also works, but only because Verilog automatically extends each 1-bit operand to fit the result width during addition — the same implicit-width-extension mechanism from the `1` vs `1'b1` lesson, just working in your favor here. It only works because `out` happens to be sized exactly wide enough (2 bits covers a max count of 3); with a wider input vector and an `out` that isn't sized to match, the same addition would silently truncate instead of erroring.

## Solution

See `popcount3.v`
