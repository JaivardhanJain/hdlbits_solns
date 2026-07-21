# Adder3

**HDLBits link:** https://hdlbits.01xz.net/wiki/Adder3
**Category:** Circuits: Combinational (Arithmetic)
**Difficulty:** ⭐⭐

## Problem summary

Build a 3-bit ripple-carry adder by instantiating the full adder from Fadd three times: two 3-bit numbers `a`, `b` and a carry-in `cin` produce a 3-bit `sum`, and the problem also wants every intermediate carry exposed as a 3-bit `cout` (not just the final one).

## Approach

This is a structural problem, not a new equation — the full adder from Fadd already does all the logic, so `top_module` just wires three copies of it together in a chain: each stage's carry-out feeds the next stage's carry-in.

```
inst1: a[0], b[0], cin      -> cout[0], sum[0]
inst2: a[1], b[1], cout[0]  -> cout[1], sum[1]
inst3: a[2], b[2], cout[1]  -> cout[2], sum[2]
```

`cout[2]` is the adder's real carry-out (the one you'd normally call "the" carry out of a 3-bit adder). `cout[0]` and `cout[1]` aren't meaningful on their own — they're internal ripple signals the problem exposes so the grader (and you) can check that each individual full adder stage is wired correctly, not just the final sum.

The `fa` module here is the same design as Fadd's `alt1.v` (the `{cout, sum} = a + b + cin` arithmetic form) — reused as a leaf cell rather than rewritten, which is the point of building it as a separate module in the first place.

## Gotchas / things I got wrong initially

- **Chaining the carries in the wrong direction.** The whole point of a ripple-carry adder is that `cout[i]` of one stage becomes `cin` of the *next* stage — get the index off by one (e.g. feed `cout[1]` into `inst2` instead of `cout[0]`) and the circuit still compiles and still "adds," but produces wrong sums for any input that generates a carry, since the carry never actually propagates through the chain correctly.
- **Naming the leaf module `top_module`.** HDLBits only looks for one module named exactly `top_module` per submission. If you copy Fadd's solution over and forget to rename its module from `top_module` to something else (`fa` here), you get a duplicate-module error, since only the top-level module in this hierarchy is allowed to keep that name — every module instantiated *underneath* it needs a distinct name.
- **Positional instantiation silently accepting a wrong port order.** `fa inst1(a[0], b[0], cin, cout[0], sum[0]);` connects by *position*, not by name — it works only because the actual argument order (`a, b, cin, cout, sum`) matches `fa`'s declared port order exactly. If `fa`'s ports were ever reordered (or someone pastes a differently-ordered full adder), a positional instantiation like this would compile fine and connect every signal to the wrong port, with zero compiler warning. Verilog also supports connecting by name — `fa inst1(.a(a[0]), .b(b[0]), .cin(cin), .cout(cout[0]), .sum(sum[0]))` — which is slower to write but immune to this class of bug; worth using by-name connections once a module has more than a couple of ports, or whenever the leaf module's port list might change independently of its callers.
- **Assuming `cout[0]` and `cout[1]` matter the way `cout[2]` does.** Since `cout` is declared as a 3-bit output, it's tempting to treat all three bits the same way you'd treat Fadd's single `cout`. Only `cout[2]` is "the" carry-out of the 3-bit sum; `cout[0]`/`cout[1]` are just the intermediate ripple carries the problem statement asks you to expose. Don't be surprised that most of the 3-bit `cout` value doesn't correspond to any single meaningful "did this addition overflow" bit.
- **Ripple-carry doesn't scale — know why, even in a 3-bit toy example.** Each stage here has to wait for the previous stage's `cout` before it can produce a correct result, so the total delay through the adder grows linearly with the number of bits. That's fine at 3 bits, but it's why real high-bit-width adders (later problems like Adder100) move to carry-lookahead or other logarithmic-delay adder structures instead of chaining full adders naively — ripple-carry is the right *teaching* structure here, not the right *production* structure at scale.

## Solution

See `adder3.v` (both `top_module` and the `fa` leaf module live in this single file, since together they form one design rather than alternative approaches).
