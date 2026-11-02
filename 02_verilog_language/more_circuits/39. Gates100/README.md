# Gates100

**HDLBits link:** https://hdlbits.01xz.net/wiki/Gates100
**Category:** Verilog Language: More Verilog Features
**Difficulty:** ⭐

## Problem summary

Build a 100-input AND, a 100-input OR and a 100-input XOR of `in[99:0]`.

## Approach

This is [Gates4](../../vectors/15.%20Gates4/README.md) with a wider input, and the code is identical apart from the port width:

```verilog
assign out_and = &in;
assign out_or  = |in;
assign out_xor = ^in;
```

A reduction operator takes its width from the operand, so `&in` covers all 100 bits without listing any of them. See [Reduction](../38.%20Reduction/README.md) for how the operators work and why `^in` is a parity bit.

## Gotchas / things I got wrong initially

- **"All ones" is not `100'b1`.** One way to write `out_and` is "is `in` all ones?", and the obvious constant is wrong. `100'b1` is the *value* 1, a 1 in bit 0 and 99 zeros above it, so `in == 100'b1` is only true for `in = 1`. Same sized-literal trap as Step One: the width prefix sets the size, not the fill. If you do want a comparison, the all-ones constant is `{100{1'b1}}` (replication, with the doubled braces from Shift18) or `~100'b0`. `&in` avoids the question entirely.

- **There's no such thing as a 100-input gate in hardware.** Synthesis breaks `&in` into a tree of smaller gates. On an FPGA with 6-input LUTs, the first level needs ⌈100/6⌉ = 17 LUTs, the second ⌈17/6⌉ = 3, and the third 1, so 21 LUTs and 3 levels of logic. A 2-input gate tree would be ⌈log₂100⌉ = 7 levels. You don't have to build the tree yourself (the tool does that from `&in`), but it's why wide reductions show up on critical paths. It's the same chain-vs-tree point as [Conditional](../37.%20Conditional/README.md), except here the tool picks the tree for you.

## Solution

See `gates100.v`
