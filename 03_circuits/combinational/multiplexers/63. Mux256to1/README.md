# Mux256to1

**HDLBits link:** https://hdlbits.01xz.net/wiki/Mux256to1
**Category:** Circuits / Combinational Logic / Multiplexers
**Difficulty:** ⭐⭐

## Problem summary

Build a 1-bit-wide 256-to-1 multiplexer. The 256 candidate inputs are packed into a single `in[255:0]` vector rather than given as 256 separate ports, and an 8-bit `sel` picks which single bit of `in` becomes `out` (`sel=0` → `in[0]`, `sel=1` → `in[1]`, etc.).

## Approach

`assign out = in[sel];` — indexing a vector with a variable rather than a constant. The synthesizer is fine with this because the thing being selected has constant width (exactly 1 bit); it builds the equivalent of a 256-way mux tree steered by the 8 bits of `sel`, without needing 256 explicit cases written out.

## Gotchas / things I got wrong initially

- **Reaching for a 256-entry `case` statement.** With 2, 9, or even a handful of inputs, writing out each case is manageable; at 256 it's unmaintainable and easy to typo one entry. The problem's own hint calls this out directly — a variable index into the vector expresses the exact same mux in one line, and it's the form that actually scales.
- **Assuming a variable index isn't synthesizable at all.** That worry is usually left over from indexing into an array of registers/memories with a variable, which does have real synthesis restrictions (and can imply a much larger structure, like a RAM read port). Selecting one constant-width bit out of a fixed vector is a different, simpler case — it's just a mux tree, and synthesis tools handle it directly.
- **Assuming the index needs to run backwards.** Because vectors in this repo are consistently declared MSB-first (`[255:0]`, following the convention from [Vector0](../../../02_verilog_language/vectors/11.%20Vector0/README.md)), it's tempting to reach for something like `in[255-sel]` on the assumption that `sel=0` should map to the "first" bit in declaration order. It doesn't — the spec pins `sel=0` to `in[0]` explicitly, and the declaration direction of the vector has no bearing on which bit index `sel` is supposed to name.
- **Sizing `sel` to anything other than exactly `$clog2(256) = 8` bits.** Here it's given as `[7:0]`, which covers indices 0–255 exactly. If you were writing this port declaration yourself rather than being handed it, under- or oversizing the select is the kind of width mistake the [`1` vs `1'b1`](../../../02_verilog_language/basics/9.%20Wire%20decl/README.md) lesson warns about — too few bits and some inputs become unreachable, too many and the extra `sel` values do nothing meaningful.

## Solution

See `mux256to1.v`
