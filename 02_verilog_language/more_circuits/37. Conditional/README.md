# Conditional

**HDLBits link:** https://hdlbits.01xz.net/wiki/Conditional
**Category:** Verilog Language: More Verilog Features
**Difficulty:** ⭐

## Problem summary

Given four 8-bit unsigned numbers `a`, `b`, `c`, `d`, output the smallest one on `min`, using the conditional (ternary) operator.

## Approach

`cond ? x : y` gives `x` when `cond` is true and `y` otherwise. It's the expression form of the `if`/`else` mux from [Always_if](../../procedures/31.%20Always_if/README.md), so it works inside a continuous `assign` with no `always` block.

A 2-way min is one line:

```verilog
assign t1 = a < b ? a : b;
```

That's a comparator driving the select of a 2-to-1 mux. Chaining three of them gives the 4-way min, with the intermediate results on 8-bit wires:

```verilog
assign t1  = a  < b ? a  : b;   // min(a, b)
assign t2  = t1 < c ? t1 : c;   // min(a, b, c)
assign min = t2 < d ? t2 : d;   // min(a, b, c, d)
```

Worked example with `a = 8'd40`, `b = 8'd25`, `c = 8'd90`, `d = 8'd7`:

| step | compare | result |
|---|---|---|
| `t1` | 40 < 25? no | 25 |
| `t2` | 25 < 90? yes | 25 |
| `min` | 25 < 7? no | 7 |

## Gotchas / things I got wrong initially

- **The comparison is only unsigned because the ports are.** `<` compares as unsigned when both operands are unsigned, which plain `input [7:0]` is. If the numbers were declared `signed` (or this were reused for signed data), the same code would compare as two's complement. `8'h80` vs `8'h01` is 128 > 1 unsigned, but −128 < 1 signed, so the "minimum" flips. Same lesson as `>>>` in Shift18: the operator's behavior depends on the operands' signedness, not on anything you write in the expression.

- **A tree is faster than a chain.** This solution is a chain: each min waits for the previous one, so the critical path goes through three comparator-plus-mux stages. Pairing them up instead gives the same answer with the same three min circuits, but only two stages deep:

  ```verilog
  assign t1  = a  < b  ? a  : b;
  assign t2  = c  < d  ? c  : d;
  assign min = t1 < t2 ? t1 : t2;
  ```

  At 4 inputs it barely matters. For N inputs the chain is N−1 stages and the tree is about log₂N, which is why min/max/priority logic in real designs is written as a tree.

- **Parenthesize nested ternaries.** `?:` has the lowest precedence of any operator, so `a < b ? a : b` already parses as `(a < b) ? a : b`, and this solution doesn't need parentheses. But once one ternary goes inside another (`a < b ? (a < c ? a : c) : (b < c ? b : c)`), the bare version is hard to read and easy to mis-nest. Parentheses, or intermediate wires as used here, make the structure obvious.

## Solution

See `conditional.v`
