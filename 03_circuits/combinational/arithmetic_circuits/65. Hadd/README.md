# Hadd

**HDLBits link:** https://hdlbits.01xz.net/wiki/Hadd
**Category:** Circuits: Combinational (Arithmetic)
**Difficulty:** ⭐

## Problem summary

Build a half adder: add two single bits with no carry-in, producing a `sum` and a `cout` (carry-out).

## Approach

A half adder has exactly four input combinations, so its truth table is small enough to read the two outputs straight off it:

| a | b | cout | sum |
|:-:|:-:|:----:|:---:|
| 0 | 0 |  0   |  0  |
| 0 | 1 |  0   |  1  |
| 1 | 0 |  0   |  1  |
| 1 | 1 |  1   |  0  |

`sum` is 1 whenever exactly one of `a`, `b` is 1 — that's the definition of XOR, so `sum = a ^ b`. `cout` is 1 only when both inputs are 1 — that's AND, so `cout = a & b`. Two gates, no intermediate wires needed.

`alt1.v` gets the same result a different way: `assign {cout, sum} = a + b;`. Verilog evaluates `a + b` as a 2-bit result (1+1 = 2, which needs 2 bits to represent), and the concatenation `{cout, sum}` on the left-hand side tells the tool where to drop each bit — `cout` gets the MSB (the carry), `sum` gets the LSB. This is the same concatenation-as-assignment-target pattern used back in Vector3, just receiving an arithmetic result instead of a bit-reversal.

## Gotchas / things I got wrong initially

- **Confusing this with a full adder's carry logic.** A full adder's `cout` is `(a&b) | (b&cin) | (a&cin)` — three terms, because it has to account for a carry-in. A half adder has no carry-in, so `cout` collapses to just `a & b`. If you paste in the full-adder formula out of habit (or copy it from a later problem), it still happens to work here only because `cin` doesn't exist — but it's a sign you're not thinking about what "half" adder actually means.
- **Assigning only `sum = a + b` and dropping the carry.** If you write `sum = a + b` where `sum` is declared as a single bit, Verilog computes `a + b` as a 2-bit value and then truncates it down to 1 bit to fit — the carry information silently disappears, and `cout` is left dangling or wrong. This is the same width-truncation trap flagged in the very first `1` vs `1'b1` lesson (Step One): Verilog will quietly narrow a wider result to fit a narrower target instead of erroring, so a half adder built purely from `+` needs the concatenation trick (`{cout, sum} = a + b`) to actually capture both output bits.
- **Getting the concatenation order backwards.** `{cout, sum} = a + b` only works because `cout` is listed first (it's the MSB of the 2-bit sum). Writing `{sum, cout} = a + b` compiles fine — same width, same operator — but silently swaps which output gets which bit, and every carry case (`a=b=1`) comes out wrong. The compiler can't catch this because both orderings are structurally valid; only the *simulation* would show it, which is exactly why gotchas about `{}` order have come up since Vector3.
- **Preferring the `a + b` version in real designs "because it's shorter."** For this exact problem either version is fine and both synthesize to the same two gates. But in industry RTL, a half adder is usually a leaf building block instantiated inside a ripple-carry or CSA adder tree, and at that level engineers write the explicit `a & b` / `a ^ b` equations rather than `+`. It documents the gate-level structure directly (useful when reviewing synthesized netlists or debugging timing on the AND/XOR paths individually) and avoids relying on the synthesis tool to infer the same two-gate structure from an arithmetic operator every time. Treat `{cout, sum} = a + b` as a handy shortcut to know, not the default for structural adder blocks.

## Solution

See `hadd.v` for the direct boolean-equation form, and `alt1.v` for the arithmetic (`+`) form.
