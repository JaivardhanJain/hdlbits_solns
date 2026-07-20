# Mux2to1

**HDLBits link:** https://hdlbits.01xz.net/wiki/Mux2to1
**Category:** Circuits / Combinational Logic / Multiplexers
**Difficulty:** ⭐

## Problem summary

Build a one-bit-wide 2-to-1 multiplexer: `out = a` when `sel = 0`, `out = b` when `sel = 1`.

## Approach

Expressed as gates: `out = (sel & b) | (~sel & a)`. Read it as "when `sel` is true, gate `b` through the AND and let the other AND term go to 0 (since `~sel` is 0); when `sel` is false, it's the reverse." The commented-out alternative, `sel ? b : a`, says the same thing with the ternary operator and reads more directly off the spec — it's the form that scales cleanly once `a`/`b` become vectors (as in the very next problem, Mux2to1v).

## Gotchas / things I got wrong initially

- **Flipping the branches.** It's easy to eyeball the spec backwards and write `sel ? a : b` or `(sel & a) | (~sel & b)` instead. Since `sel=0` selects `a`, the term gated by the *un-inverted* `sel` must be `b`, not `a` — worth double-checking against the spec every time rather than trusting a quick read.
- **Relying on `&` binding tighter than `|` without parentheses.** `sel & b | ~sel & a` does evaluate correctly unparenthesized, because Verilog gives `&` higher precedence than `|` (same as C). That's a fact worth knowing, not assuming — in longer expressions mixing several bitwise operators, an incorrect precedence assumption is a real source of silent bugs, so parenthesizing explicitly (or using the ternary form) is the safer habit even when it isn't strictly required.
- **Reaching for logical operators (`&&`, `||`, `!`) instead of bitwise (`&`, `|`, `~`).** For single-bit `a`/`b`/`sel` here the truth tables are identical, so a logical-operator version would still pass — but it breaks the bitwise-for-datapath convention from [Norgate](../../basic_gates/7.%20Norgate/README.md), and the difference stops being cosmetic the moment any of these signals becomes a multi-bit vector, which happens immediately in the next problem (Mux2to1v). Bitwise operators are the ones that generalize.
- **Building this with `always @(*)` + `if/else` (or `case`) instead of `assign`.** It's a valid alternative, but forgetting the `else` branch (or a `default` in a `case`) leaves `out` undriven for some input combination, and the synthesis tool infers a latch instead of a mux. The `assign`/ternary form used here sidesteps the issue entirely, since a continuous assignment always has a value for every combination of inputs.

## Solution

See `mux2to1.v`
