# Adder100i

**HDLBits link:** https://hdlbits.01xz.net/wiki/Adder100i
**Category:** Verilog Language: More Verilog Features
**Difficulty:** ⭐⭐⭐

## Problem summary

Build a 100-bit ripple-carry adder by instantiating 100 full adders. Add `a`, `b` and `cin`, and output both the 100-bit `sum` and the carry-out of **every** full adder on `cout[99:0]`. `cout[99]` is the final carry-out.

## Approach 1 — generate-for with 100 full adders (`adder100i.v`)

This is [Adder3](../../../03_circuits/combinational/arithmetic_circuits/67.%20Adder3/README.md) scaled from 3 stages to 100, so it reuses the same `fa` full adder:

```verilog
module fa(input a, b, cin, output cout, sum);
    assign {cout, sum} = a + b + cin;
endmodule
```

Adder3 wrote its three instances out by hand. At 100 stages that's not practical, so a generate-for loop creates them, as in the `alt1.v` of [Vector100r](../40.%20Vector100r/README.md), but with module instances instead of `assign`s. Instances are exactly the case where a generate block is required: an `always` block can't contain one.

```verilog
wire [99:0] carry_in = {cout[98:0], cin};

genvar i;
generate
    for (i = 0; i < 100; i = i + 1) begin : fa_chain
        fa u_fa (.a(a[i]), .b(b[i]), .cin(carry_in[i]), .cout(cout[i]), .sum(sum[i]));
    end
endgenerate
```

The only irregular stage is stage 0, whose carry comes from `cin` instead of the previous stage. The `carry_in` wire takes care of it: shifting `cout` up one bit and putting `cin` at the bottom gives

| stage `i` | `carry_in[i]` |
|---|---|
| 0 | `cin` |
| 1 | `cout[0]` |
| 2 | `cout[1]` |
| … | … |
| 99 | `cout[98]` |

so one instantiation line works for every stage. The instances are named `fa_chain[0].u_fa` through `fa_chain[99].u_fa`.

## Approach 2 — procedural for loop (`alt1.v`)

```verilog
always @(*) begin
    {cout[0], sum[0]} = a[0] + b[0] + cin;
    for (int i = 1; i < 100; i++)
        {cout[i], sum[i]} = a[i] + b[i] + cout[i-1];
end
```

Each iteration is one full adder written inline. Stage 0 is pulled out before the loop, and the loop starts at 1. It reads `cout[i-1]` from the previous iteration, which works for the same reason as Popcount255's running total: blocking `=` updates immediately, so iteration `i` sees what iteration `i-1` just wrote. This synthesizes to the same 100-stage carry chain.

## Gotchas / things I got wrong initially

- **The spec asks for instances, and the loop version has none.** HDLBits only checks the outputs, so `alt1.v` passes. But "instantiate 100 full adders" is a structural requirement, and only `adder100i.v` meets it. In a real design the difference matters when the cell is something you can't write inline: a hand-optimized adder from a cell library, or a block that has its own verification.

- **Stage 0 is the off-by-one trap.** The tempting version runs the loop from `i = 0` with `cout[i-1]` as the carry. At `i = 0` that reads `cout[-1]`, which doesn't exist. In simulation an out-of-range read returns `x`, so `sum[0]` and `cout[0]` become `x`, then `cout[1]`, and so on: one bad index makes the whole 100-bit result `x`. In a generate loop the same mistake is an elaboration error or warning, depending on the tool. Both solutions handle stage 0 explicitly: `alt1.v` by peeling it off before the loop, `adder100i.v` with the `carry_in` wire.

- **The two versions need opposite output declarations.** In `adder100i.v`, `cout` and `sum` are driven by instance output ports, so they must be nets, and the bare `output [99:0]` is correct. In `alt1.v` they're assigned inside an `always` block, so portable code needs `output reg` or `output logic`. As in Popcount255, Icarus Verilog rejects `alt1.v` with HDLBits's header and accepts it once the outputs are `output logic`. Same signal, same circuit, opposite declaration depending on how it's driven — the `reg` vs. net theme again.

- **A ripple-carry adder is slow at 100 bits.** The worst case is a carry that starts at stage 0 and ripples through all 100 stages, e.g. `a` all ones, `b = 0`, `cin = 1`. That's a 100-stage critical path. Real wide adders use carry-lookahead or parallel-prefix structures (the tree idea from [Conditional](../37.%20Conditional/README.md)), and writing plain `a + b + cin` lets the synthesis tool pick one. This problem forces the ripple structure because it wants every intermediate carry exposed.

## Solution

See `adder100i.v` (100 `fa` instances via generate-for) and `alt1.v` (procedural for loop, no instances).
