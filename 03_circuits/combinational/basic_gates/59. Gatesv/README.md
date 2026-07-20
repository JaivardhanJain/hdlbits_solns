# Gatesv

**HDLBits link:** https://hdlbits.01xz.net/wiki/Gatesv
**Category:** Circuits / Combinational Logic / Basic Gates
**Difficulty:** ⭐⭐

## Problem summary

Given a 4-bit vector `in[3:0]`, compare each bit to its neighbour: `out_both[2:0]` is the AND of each bit with its left neighbour, `out_any[3:1]` is the OR of each bit with its right neighbour, and `out_different[3:0]` is the XOR of each bit with its left neighbour, wrapping around so `in[3]`'s left neighbour is `in[0]`.

## Approach

Each output is a shifted version of `in` combined bitwise with `in` itself, so the whole circuit is three continuous assigns with no loop needed:
- `out_both = in[3:1] & in[2:0]` pairs each bit with its left neighbour by AND-ing the vector against a copy of itself shifted down by one.
- `out_any = in[3:1] | in[2:0]` does the same pairing with OR.
- `out_different = in ^ {in[0], in[3:1]}` needs the wraparound, so the shifted copy is built with concatenation: `{in[0], in[3:1]}` moves `in[0]` up to the top bit and shifts `in[3:1]` down by one, which is exactly "rotate left by one." XOR-ing that against `in` gives each bit XOR'd with its left neighbour, `in[3]` included.

## Gotchas / things I got wrong initially

- Typo'd `out_different` as `out_dfferent` in the assign statement. Verilog's default implicit-net behavior means this doesn't error: `out_dfferent` silently becomes a new 1-bit wire nobody asked for, while the actual output port `out_different` is left undriven (reads as `x` in simulation, and HDLBits's grader flags it as incorrect with no compile-time hint pointing at the typo). This is the same failure mode called out in [Declaring wires](../../../02_verilog_language/basics/9.%20Wire%20decl/README.md) — `` `default_nettype none `` at the top of the file would have turned this into a compile error instead of a silent mismatch.
- It's tempting to reach for a `for` loop or reference each neighbour bit individually (`in[3]^in[0]`, `in[2]^in[3]`, ...) to handle the wraparound on `out_different`. A single concatenation-built rotated copy (`{in[0], in[3:1]}`) does the same job in one line and scales the same way the reduction operators in [Four-input gates](../../../02_verilog_language/vectors/15.%20Gates4/README.md) do — worth reaching for concatenation before a loop on fixed, small widths like this.

## Solution

See `gatesv.v`
