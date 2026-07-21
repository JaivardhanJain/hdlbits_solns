# Mux256to1v

**HDLBits link:** https://hdlbits.01xz.net/wiki/Mux256to1v
**Category:** Circuits / Combinational Logic / Multiplexers
**Difficulty:** ⭐⭐⭐

## Problem summary

Build a 4-bit-wide 256-to-1 multiplexer. The 256 candidate 4-bit inputs are packed into a single `in[1023:0]` vector; `sel` picks which 4-bit group becomes `out` (`sel=0` → `in[3:0]`, `sel=1` → `in[7:4]`, `sel=2` → `in[11:8]`, etc. — each group starts at bit `sel*4`).

## Approach

`assign out = {in[sel*4+3], in[sel*4+2], in[sel*4+1], in[sel*4+0]};` — pick out the four individual bits of the selected group with a variable single-bit index (which [Mux256to1](../63.%20Mux256to1/README.md) already established works fine), then concatenate them back into a 4-bit bus in MSB-to-LSB order. It's more verbose than a single part-select, but it only relies on variable-index rules the synthesizer is guaranteed to handle.

## Gotchas / things I got wrong initially

- **Reaching for `in[sel*4+3 : sel*4]` as a "multi-bit version" of the Mux256to1 trick.** This looks like the natural next step from single-bit variable indexing, but ordinary part-select syntax (`[msb:lsb]`) requires both bounds to be constant — here both bounds depend on `sel`, so most synthesis tools reject it with an error like "... is not a constant," even though the *width* of the selection (4) never changes. The per-bit-then-concatenate version above avoids this because each index (`sel*4+0`, `sel*4+1`, ...) selects exactly one bit, and a single-bit selection is always constant-width.
- **Not knowing about indexed part-select (`+:` / `-:`) as the cleaner fix.** `in[sel*4 +: 4]` (base `sel*4`, climbing upward through 4 bits) or `in[sel*4+3 -: 4]` (base `sel*4+3`, descending through 4 bits) say the same thing as the concatenation in one line each. The syntax is unfamiliar next to ordinary `[msb:lsb]` part-select, which is likely why it doesn't occur to people by default — but it's the idiomatic way to write a variable-base, fixed-width slice, and it's what the per-bit concatenation is manually working around.
- **Assuming the width still has to be constant even with `+:`/`-:`.** These operators only relax the *base* into something variable (`sel*4`); the width (`4`) after the operator must still be a compile-time constant. Writing something like `in[sel*4 +: sel]` to try to make the width itself variable doesn't synthesize for the same reason the plain part-select didn't — the synthesizer still needs to know the exact width of the selection up front.
- **Getting the concatenation order backwards.** `{in[sel*4+3], in[sel*4+2], in[sel*4+1], in[sel*4+0]}` places the highest-indexed bit first because Verilog concatenation lists MSB first — reversing the list would silently swap the bit order of every output nibble. Worth double-checking against the MSB-first convention from [Vector0](../../../02_verilog_language/vectors/11.%20Vector0/README.md) rather than assuming concatenation order doesn't matter.

## Solution

See `mux256to1v.v`
