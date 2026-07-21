# Fadd

**HDLBits link:** https://hdlbits.01xz.net/wiki/Fadd
**Category:** Circuits: Combinational (Arithmetic)
**Difficulty:** ⭐

## Problem summary

Build a full adder: add three bits — `a`, `b`, and a carry-in `cin` — producing a `sum` and a `cout`.

## Approach

Adding a carry-in to the half adder from the previous problem changes both outputs, so it's worth re-deriving them rather than just patching Hadd's equations:

| a | b | cin | cout | sum |
|:-:|:-:|:---:|:----:|:---:|
| 0 | 0 |  0  |  0   |  0  |
| 0 | 0 |  1  |  0   |  1  |
| 0 | 1 |  0  |  0   |  1  |
| 0 | 1 |  1  |  1   |  0  |
| 1 | 0 |  0  |  0   |  1  |
| 1 | 0 |  1  |  1   |  0  |
| 1 | 1 |  0  |  1   |  0  |
| 1 | 1 |  1  |  1   |  1  |

`sum` is 1 whenever an odd number of the three inputs are 1 — XOR generalizes cleanly to any number of inputs this way, so `sum = a ^ b ^ cin`. `cout` is 1 whenever at least two of the three inputs are 1 (a "majority vote"), which written as a sum of products is `(a&b) | (a&cin) | (b&cin)` — one term per pair.

`alt1.v` again gets there through arithmetic instead of boolean algebra: `assign {cout, sum} = a + b + cin;`. Three 1-bit operands sum to at most 3 (`1+1+1`), which needs 2 bits to represent, so the same `{cout, sum}` concatenation from Hadd captures both output bits in one line.

## Gotchas / things I got wrong initially

- **Reusing the half adder's `cout` formula and forgetting `cin`.** Hadd's gotchas section already warned about the reverse mistake — pasting a full adder's carry logic into a half adder. Here it's easy to make the opposite error: if you build this by copy-pasting Hadd's `cout = a & b` and just adding cin somewhere carelessly (e.g. `cout = (a & b) | cin`), you'll pass the easy cases but fail whenever exactly one of `a`/`b` is 1 and `cin` is also 1 — that case needs its own product term, not an OR tacked onto the two-input result.
- **Dropping `cin` from the XOR chain.** Similarly, writing `sum = a ^ b` (forgetting `cin` entirely) passes every test case where `cin = 0` and fails every case where `cin = 1` — a full third of the truth table. Since XOR chains generalize (`a ^ b ^ cin` is just "parity of all three inputs"), it's easy to assume the two-input form still applies once a third input shows up.
- **Relying on `&`/`|` precedence without parentheses.** `cout = a & b | a & cin | b & cin` only parses correctly because Verilog gives `&` higher precedence than `|` (same convention as C), so it's read as `(a & b) | (a & cin) | (b & cin)`. That's valid, but leaving out the parentheses makes the sum-of-products structure harder to see at a glance and is an easy source of bugs the moment the expression grows (e.g. if a `~` or `^` gets mixed in later, as flagged back in the Norgate gotchas on operator precedence). Writing out `(a & b) | (a & cin) | (b & cin)` costs nothing and makes the "OR of three AND-pairs" structure explicit.
- **Truncating the carry from the arithmetic form.** Same trap as Hadd: `a + b + cin` is a 3-valued result that needs 2 bits, so assigning it to a 1-bit `sum` alone silently drops `cout`. The `{cout, sum} = a + b + cin` concatenation is required, in the same MSB-first order as before, to capture both bits correctly.

## Solution

See `fadd.v` for the direct boolean-equation form, and `alt1.v` for the arithmetic (`+`) form.
