# Vector3

**HDLBits link:** https://hdlbits.01xz.net/wiki/Vector3
**Category:** Verilog Vectors
**Difficulty:** ⭐

## Problem summary

Given several input vectors, concatenate them and separate them into several output vectors.


## Approach

Use the concatenation operators.

## Gotchas / things I got wrong initially
 - Every piece inside `{}` must have an explicit, known width — that's how Verilog figures out the total result width. `{1, 2, 3}` is illegal ("unsized constants are not allowed in concatenations") for the same reason `1` vs `1'b1` mattered back in Step One: an unsized literal has no fixed width for Verilog to reason about, and concatenation needs one for every component.
 - Concatenation works on both sides of an assignment, and this solution uses it on both: `{a, b, c, d, e, f, 1'b1, 1'b1}` builds a 32-bit value on the right, and `{w, x, y, z}` is a 32-bit concatenation on the left to receive it. Since both sides are exactly 32 bits, there's no implicit extension or truncation to worry about — if the LHS concatenation total didn't exactly match the RHS width, the usual zero-extend/truncate rules from Step One and Vector1 would kick in instead.

Quick reference:
```verilog
{3'b111, 3'b000}          // => 6'b111000
{1'b1, 1'b0, 3'b101}      // => 5'b10101
{4'ha, 4'd10}              // => 8'b10101010 (4'ha and 4'd10 are both 4'b1010)
```

## Solution

See `vector3.v`
