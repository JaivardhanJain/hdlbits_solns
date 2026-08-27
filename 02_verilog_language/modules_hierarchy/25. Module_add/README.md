# Module_add

**HDLBits link:** https://hdlbits.01xz.net/wiki/Module_add
**Category:** Verilog Language: Modules: Hierarchy
**Difficulty:** ⭐⭐

## Problem summary

Given a 16-bit adder `add16` that computes `a + b + cin` and produces `sum` and `cout`, build a 32-bit adder from two of them. The top-level takes no carry in and produces no carry out.

## Approach

A ripple-carry adder, one level up the hierarchy: instead of chaining full adders bit by bit, we chain 16-bit blocks.

```
   a[15:0]  b[15:0]              a[31:16] b[31:16]
      |        |                     |        |
   +--v--------v--+   c   ---->  +---v--------v--+
   |     a1       |------------->|      a2       |
   +------|-------+  cin         +-------|-------+
     sum[15:0]                      sum[31:16]      cout -> discarded
      cin = 0
```

Three connection decisions carry the whole design:

- **`a1.cin` is tied to `1'b0`** — the low half has nothing below it. Tying a constant to an *input* port is fine and common; the constant is a source, and the port is a sink.
- **`c` carries `a1.cout` into `a2.cin`.** This single wire is what makes two independent 16-bit adders into one 32-bit adder.
- **`a2.cout` is discarded**, because a 32-bit adder that produces a 32-bit sum has nowhere to put bit 32. It's left explicitly unconnected.

The vector slicing is the other half of the work: `a[15:0]`/`a[31:16]` split the 32-bit operands into halves that match `add16`'s 16-bit ports, and `sum[15:0]`/`sum[31:16]` reassemble the result. Part-selects on the *left* of a port connection are legal precisely because `sum` is a net — each instance drives its own disjoint slice, so there's no multiple-driver conflict.

Ports are connected by name here, which at five ports is no longer optional in any practical sense.

## Gotchas / things I got wrong initially

- **You cannot tie an unused output to a constant.** Writing `.cout(1'b0)` on `a2` is the intuitive way to say "I don't care about this," and it's illegal: `1'b0` is a constant expression, not a net, and an output port has to drive something drivable. The correct spelling for a deliberately unused output is the empty connection `.cout()`, which documents the intent and connects nothing. This is worth internalising because the mirror-image case *is* legal — an unused **input** tied to `1'b0` is completely normal, which is exactly why the output version looks plausible. Direction decides: constants may feed inputs, never outputs.

- **Omitting the port entirely also works, but says less.** `add16 a2 ( .a(...), .b(...), .cin(c), .sum(...) );` compiles and behaves identically to `.cout()`. The explicit empty form is better style because a reader can see you considered `cout` and chose to drop it, rather than wondering whether you forgot it — the same argument made back in Module (20).

- **Forgetting to tie `a1.cin` low leaves it floating.** Nothing drives it, so it reads `x`, and the entire 32-bit sum becomes `x` — not just the low bit. Unlike a wrong constant, this failure is loud in simulation, but it's easy to introduce by pattern-matching `a2`'s connection list onto `a1`.

- **Slice bounds must match the port width exactly.** `a[15:0]` is 16 bits and `add16.a` is 16 bits, so they agree. Typo it to `a[16:0]` and Verilog silently truncates rather than erroring, quietly losing a bit — the same silent-resize hazard raised in Module_shift8 and traceable back to Step One. Counting `31:16` as sixteen bits (not fifteen) is worth doing deliberately.

- **Getting the halves backwards is a silent functional bug.** Feeding `a[31:16]` to `a1` and `a[15:0]` to `a2` compiles perfectly, and produces a number that is wrong in a way no width check will catch. The carry direction is the tell: carry always propagates from less significant to more significant, so the instance driving `sum[15:0]` must be the one *sourcing* `c`.

- **`sum` stays a `wire`.** It's driven structurally by two instances, each on its own bit range, so no `reg` is involved — contrast Module_shift8, where the mux assigned `q` procedurally and `output reg` was required. The rule remains "is it assigned inside a procedural block?", not "is it an output?".

- **`c` is 1 bit and must be declared.** As a scalar it *would* be auto-created if you forgot, silently, which is the Wire_decl / Gatesv implicit-net trap — and here the implicit net would still work, making the omission invisible until `` `default_nettype none `` is turned on somewhere downstream.

## Solution

See `module_add.v`
