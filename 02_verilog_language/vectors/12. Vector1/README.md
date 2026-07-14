# Vector1

**HDLBits link:** https://hdlbits.01xz.net/wiki/Vector1
**Category:** Verilog Vectors
**Difficulty:** ⭐

## Problem summary

Using vector part-select to split a 16-bit vector into 2 halves.


## Approach

Use continuous assigns and vector part-select syntax.

## Gotchas / things I got wrong initially
 - A vector's endianness (declared direction, e.g. `[15:0]` vs `[0:15]`) is fixed once declared and must be used consistently everywhere — `in[0:15]` on a vector declared `[15:0]` is illegal, not just bad style. Mixing vectors of different endianness in the same expression is a real source of subtle bugs, so pick one direction (MSB-first, `[N-1:0]`) and stay consistent across the whole design.
 - Part-select direction must match the declaration's direction: if `in` is `[15:0]`, `in[15:8]` is valid but `in[8:15]` is not — it's a compile error, not a logic bug, so it fails fast at least.
 - Implicit nets are a real trap here: an `assign` to (or module port connection with) an undeclared identifier silently creates a 1-bit wire instead of erroring. If you typo a vector's name in an `assign`, you don't get a compile error — you get a new, wrong, 1-bit wire, and everything downstream silently truncates. `` `default_nettype none `` turns this into a hard compile error instead of a silent bug.
 - Whole-vector assignment (`assign out = in;`) zero-extends or truncates automatically if the widths don't match — same width-matching principle as sized vs. unsized literals, just at the vector level. Worth double-checking widths explicitly rather than relying on implicit padding/truncation.

## Solution

See `vector1.v`
