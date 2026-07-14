# Vector2

**HDLBits link:** https://hdlbits.01xz.net/wiki/Vector2
**Category:** Verilog Vectors
**Difficulty:** ⭐

## Problem summary

Using vector part-select to split a 32-bit vector into 4 Bytes.


## Approach

Use continuous assigns and vector part-select syntax.

## Gotchas / things I got wrong initially
 - You could also use the concatenation operator '{}' and use one assign. assign {out[31:24], out[23:16], out[15:8], out[7:0]} = in;. Note that if you use the concatenation on the LHS, everything has to be something that can be driven, i.e. you can't use assign{1'b0, out} = in;
 - This operation is often used when the endianness of a piece of data needs to be swapped, for example between little-endian x86 systems and the big-endian formats used in many Internet protocols.

## Solution

See `vector2.v`
