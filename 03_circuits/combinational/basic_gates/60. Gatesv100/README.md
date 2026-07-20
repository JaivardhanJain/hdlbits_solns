# Gatesv100

**HDLBits link:** https://hdlbits.01xz.net/wiki/Gatesv100
**Category:** Circuits / Combinational Logic / Basic Gates
**Difficulty:** ⭐⭐

## Problem summary

Identical spec to [Gatesv](../59.%20Gatesv/README.md), just widened to a 100-bit input: `out_both[98:0]` ANDs each bit with its left neighbour, `out_any[99:1]` ORs each bit with its right neighbour, and `out_different[99:0]` XORs each bit with its left neighbour, wrapping `in[99]` around to `in[0]`.

## Approach

Widen the port declarations to 100 bits and reuse the exact same three assign statements from Gatesv unchanged — the part-selects and concatenation are relative to the vector's own width, so nothing in the logic needed to be rewritten for the wider bus.

## Gotchas / things I got wrong initially

- The "100" in the name suggests reaching for a `generate`/`for` loop like [adder100i](https://hdlbits.01xz.net/wiki/adder100i) or the procedural loops from [Vectorr](../../../02_verilog_language/vectors/17.%20Vectorr/README.md). Not needed here — the vector solution from Gatesv already generalizes to any width for free, since `in[98:0]`, `in[99:1]`, and the rotate-by-concatenation trick are all expressed relative to the vector's own bounds, not hardcoded bit positions. A loop would just be solving a problem that copy-pasting already solves.
- This is the payoff of writing Gatesv with part-selects and concatenation instead of naming individual bits (`in[3]`, `in[2]`, ...): a per-bit approach would have to be rewritten by hand for 100 inputs, while the vector approach ports over with zero changes to the assign statements themselves, only the port widths change.

## Solution

See `gatesv100.v`
