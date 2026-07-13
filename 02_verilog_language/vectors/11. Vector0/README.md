# Vector0

**HDLBits link:** https://hdlbits.01xz.net/wiki/Vector0
**Category:** Verilog Vectors
**Difficulty:** ⭐

## Problem summary

Circuit with a 3-bit input that outputs the vector as is, as well as splits it up into 3 others outputs.


## Approach

Use continuous assigns and vector syntax. 

## Gotchas / things I got wrong initially
 - Notice that the declaration of a vector places the dimensions before the name of the vector, which is unusual compared to C syntax. However, the part select has the dimensions after the vector name as you would expect.
 - `vec` is declared `[2:0]`, so `vec[2]` is the MSB and `vec[0]` is the LSB. Swapping this when wiring `o2`/`o1`/`o0` individually still compiles (each output is 1 bit either way), just to the wrong bit — the classic bug on this problem is a silent MSB/LSB mixup, not a compile error.
 - Always declare vectors MSB-first (`[N-1:0]`), not LSB-first (`[0:N-1]`). Both are legal Verilog, but LSB-first flips index semantics in ways that break assumptions in later code (part-selects, loops, arithmetic) and reads as a mistake to anyone else. MSB-first is the near-universal convention.
 - The concatenation operator is an alternative to individual part-selects: `assign {o2, o1, o0} = vec;` does all three connections in one statement (order in the `{}` matches bit order — leftmost is the MSB). Worth knowing early since `{}` shows up constantly in later vector problems.

## Solution

See `vector0.v`
