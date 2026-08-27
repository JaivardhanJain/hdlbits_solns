# Module_cseladd

**HDLBits link:** https://hdlbits.01xz.net/wiki/Module_cseladd
**Category:** Verilog Language: Modules: Hierarchy
**Difficulty:** ⭐⭐⭐

## Problem summary

Build the same 32-bit adder as [Module_add](../25.%20Module_add/README.md), but as a **carry-select** adder: three `add16` instances plus a 16-bit-wide 2-to-1 mux, instead of two adders chained by a carry.

## Approach

The ripple-carry version in Module_add is slow for a structural reason — the upper adder cannot start until the lower one has finished, because it needs that carry bit. Delay is the sum of both stages.

Carry-select removes the wait by **speculating**. The carry into the upper half can only ever be 0 or 1, so compute both answers at once and throw one away:

```
                          a[31:16], b[31:16]
                             |          |
   a[15:0] b[15:0]     +-----v----------v-----+  cin=0
      |       |        |         a2           |------> t2 --+
   +--v-------v--+     +----------------------+             |
   |     a1      |                                          +--> mux --> sum[31:16]
   +------|------+     +----------------------+  cin=1      |     ^
    sum[15:0]  t1      |         a3           |------> t3 --+     |
    cin=0       |      +----------------------+                   |
                +--------------------------------------------- select
```

`a2` and `a3` add the identical operands and differ only in `cin`. Both start immediately, in parallel with `a1`. When `a1`'s carry `t1` finally arrives, it doesn't feed an adder — it feeds a mux, so the remaining delay is one mux instead of one full 16-bit addition.

That's the classic area-for-speed trade: three adders instead of two (50% more logic) to make the critical path *one adder plus a mux* rather than *two adders*. The idea generalises — real designs stack it across more blocks — and it's the first genuinely architectural decision in this chapter, as opposed to a wiring exercise.

The mux is written with a `case` inside `always @(*)`, the same shape as Module_shift8's 4-to-1. `alt1` in the solution file uses a conditional continuous assignment (`t1 ? t3 : t2`) instead, which is more compact for a 2-to-1 and avoids needing a `reg` at all.

## Gotchas / things I got wrong initially

- **`sum` cannot be part-net, part-`reg`.** This is the real trap of the problem. `a1` drives `sum[15:0]` structurally through a port connection, so `sum` must be a net. But an `always` block can only assign to a `reg`. Writing `sum[31:16] = t2;` inside the block is therefore illegal, and declaring `output reg [31:0] sum` doesn't rescue it — that just breaks `a1` instead, since a module output port can't drive a `reg`. The fix is an intermediate: assign the mux result to a `reg [15:0] hi`, then `assign sum[31:16] = hi;`. One vector, two halves, two different driving mechanisms — they have to meet at a continuous assignment. (`alt1` sidesteps the whole issue by not using a procedural block.)

- **`.cout(1'b0)` is illegal, twice over here.** Both `a2` and `a3` produce a carry nobody wants, and the temptation to "tie it off" with a constant is strongest when there are several. An output port cannot be driven by a constant; use the empty connection `.cout()`. Third appearance of this one across Module_add, Module_fadd, and now here.

- **`a2` and `a3` must receive the *same* operands.** They differ only in `cin`. Splitting the operands between them — giving `a3` the low half, say — silently produces nonsense, because the whole premise is that they compute the two possible answers for the *same* addition. Easy to introduce when copy-pasting the instantiation.

- **`t1` comes from `a1`, not from `a2`.** The select must be the *real* carry out of the low half. `a2.cout` and `a3.cout` are carries out of speculative additions and are meaningless as a select. Using one of them compiles fine and gives a wrong answer.

- **The mux is 16 bits wide, not 1.** `t2` and `t3` must be declared `wire [15:0]`. Declaring them bare (`wire t2, t3;`) makes them 1 bit, silently truncating each speculative sum to its LSB — the vector-width hazard from Module_shift8, and it produces a result that looks almost right for small operands.

- **Both `case` arms are present, so no latch.** `t1` is 1 bit and both values are covered, which is what keeps the block combinational. A `default:` would be the more robust habit — see the note in Module_shift8, and the always_nolatches problem later.

- **This is still purely combinational despite the speculation.** Nothing is clocked; "compute both in parallel" describes gates that all settle at once, not two sequential attempts. Worth stating plainly, because "speculation" borrows vocabulary from processor design where it usually does involve state.

## Solution

See `module_cseladd.v`
