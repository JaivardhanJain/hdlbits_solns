# Gates4

**HDLBits link:** https://hdlbits.01xz.net/wiki/Gates4
**Category:** Verilog Vectors
**Difficulty:** ⭐

## Problem summary

Taking a 4-bit vector input and passing it through gates with multiple inputs.


## Approach

Use continuous assigns and use bitwise operators as reduction operators.

## Gotchas / things I got wrong initially
 - Unary reduction operators (`&`, `|`, `^`, and their negations `~&`, `~|`, `~^`) take a single vector and collapse it to 1 bit by applying the operator between every bit: `&in` is `in[0] & in[1] & in[2] & in[3]` (1 only if all bits are 1), `|in` is the OR of all bits (1 if any bit is 1), `^in` is the XOR of all bits (1 if an odd number of bits are 1 — a parity check). This scales to any width for free, unlike writing out `in[0] & in[1] & in[2] & in[3]` by hand, which doesn't generalize when the vector gets wider (see `gates100`).
 - Same symbol, different operator depending on operand count: `&` with one operand is a reduction (collapses one vector to 1 bit); `&` with two operands is bitwise AND (produces a vector the width of the operands). Skimming code without noticing whether `&` is unary or binary is an easy misread.
 - Reduction (`&in`) and logical (`&&`) look similar but do different things: `&in` collapses the bits *within* one vector; `a && b` collapses two separate operands to booleans and ANDs those. Don't conflate "reduce a vector" with "logical-AND two signals" just because both end up 1 bit wide.
 - The solution file was initially misnamed `vectorgates.v` (copied over from the previous problem's folder) instead of `gates4.v` — renamed to match the README and the repo's naming convention.

## Solution

See `gates4.v`
