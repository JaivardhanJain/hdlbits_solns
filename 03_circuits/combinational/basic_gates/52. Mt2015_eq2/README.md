# Mt2015_eq2

**HDLBits link:** https://hdlbits.01xz.net/wiki/Mt2015_eq2
**Category:** Verilog Basics
**Difficulty:** ⭐⭐

## Problem summary

Given two 2-bit inputs A and B, output z = 1 if A equals B, else 0.

## Approach

Use the equality operator (`==`) directly on the two buses and assign the result to z; no bit-by-bit comparison needed.

## Gotchas / things I got wrong initially
- `==` isn't limited to single bits — it compares whole buses at once and gives you a 1-bit pass/fail result directly, so there's no need to compare A[1] to B[1] and A[0] to B[0] separately and AND the results together.
- It's tempting to expand this into a 4-input truth table ({A,B} → 16 rows, with 0000, 0101, 1010, 1111 as the 1-minterms), the same way we did for Truthtable1. It's still wasteful here for the same reason it was there: writing out and simplifying a full SOP is extra work to reconstruct logic that `==` already gives you in one line.
- A more subtle trap: reimplementing equality by hand as `&(A ~^ B)` (bitwise XNOR each bit, then reduction-AND the results). This works, but it's the Norgate/Andgate bitwise-vs-logical confusion resurfacing — `~^` is a bitwise op that returns a vector, and it's easy to forget the reduction `&` and end up assigning a multi-bit vector to a 1-bit output (implicit truncation just silently takes bit 0). `==` does the reduction for you and is the more idiomatic choice for whole-bus comparisons.
- Worth knowing for real designs even though it doesn't bite on HDLBits: `==` is 2-state equality and can return `x` if either operand has an unknown bit, whereas `===` (case equality) always resolves to 0 or 1, including against `x`/`z`. Testbenches checking for `x` propagation should reach for `===`, not `==`.

## Solution

See `Mt2015_eq2.v`
