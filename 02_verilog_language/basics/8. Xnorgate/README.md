# Xnorgate

**HDLBits link:** https://hdlbits.01xz.net/wiki/Xnorgate
**Category:** Verilog Basics
**Difficulty:** ⭐

## Problem summary

Xnor the inputs and wire them to the output.


## Approach

Verilog has a built-in bitwise-XNOR operator, `~^` (equivalently `^~`), so the whole gate is one line: `assign out = a ~^ b;`. No AND/OR/NOT construction needed.

## Gotchas / things I got wrong initially
 - Note that XOR means only one is high (both bits are different values). Thus an XNOR is the opposite, both bits have the same value.
 - You can build XNOR manually as `(a & b) | (~a & ~b)` (both high, or both low), which is good for understanding the boolean algebra, but prefer the built-in `~^` operator in practice — it's shorter and avoids precedence mistakes entirely.
 - I initially wrote `(!a & !b)` as `!(a & b)`, thinking the `!` could just move outside since it's applying to both terms. It can't: Verilog operator precedence puts unary `!`/`~` above binary `&`, so `!(a & b)` computes NAND (0 only when both are high), while `(!a & !b)` computes "both low" (1 only when both are low) — different logic entirely. Also, `!` is the logical-NOT operator; on bitwise data-path logic like this, `~` is the correct one to use (`!a` and `~a` happen to agree on a 1-bit signal, but `~` is the one that generalizes to vectors).

## Solution

See `xnor_gate.v`
