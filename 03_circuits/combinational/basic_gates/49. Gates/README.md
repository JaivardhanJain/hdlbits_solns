# Gates

**HDLBits link:** https://hdlbits.01xz.net/wiki/Exams/Gates
**Category:** Verilog Basics
**Difficulty:** ⭐

## Problem summary

Given two inputs, pass them through various logic gates to get 7 outputs.

## Approach

Just a continuous assignment (`assign`) with the logic of the respective output. 

## Gotchas / things I got wrong initially
- Used `&&`/`||`/`^^` (logical operators) instead of `&`/`|`/`^` (bitwise operators). They give the same result here because `a` and `b` are single bits, but logical operators reduce their operands to one truth value rather than modeling per-bit gates — this breaks silently on multi-bit vectors, and `^^` isn't standard Verilog (it's a SystemVerilog addition). Use bitwise operators for gate-level logic; reserve `&&`/`||`/`!` for conditions (`if`, ternary).

## Solution

See `gates.v`
