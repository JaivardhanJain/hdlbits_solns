# Module_addsub

**HDLBits link:** https://hdlbits.01xz.net/wiki/Module_addsub
**Category:** Verilog Language: Modules: Hierarchy
**Difficulty:** ⭐⭐⭐

## Problem summary

The 32-bit ripple-carry adder from [Module_add](../25.%20Module_add/README.md), extended with a `sub` input: compute `a + b` when `sub` is 0 and `a - b` when `sub` is 1, still using only the two provided `add16` blocks.

## Approach

An adder can subtract for free, because in two's complement

```
-b  =  ~b + 1
```

so `a - b` is just `a + ~b + 1`. Both extra pieces are already available:

- **`~b`** — invert every bit of `b`, but only when `sub` is set.
- **`+ 1`** — the low adder's `cin` is sitting unused at `1'b0`. Drive it with `sub` instead and the increment costs nothing.

That's the whole design. `sub` does double duty: it controls the inversion and supplies the carry-in.

```
       sub                       sub
        |                         |
        v                         v
  b --> XOR --> b_sub --> [add16] --> [add16] --> sum
        ^                  cin=sub      cin=c
        |
      {32{sub}}
```

Conditional inversion via XOR is the standard idiom: `x ^ 0 = x` and `x ^ 1 = ~x`, so XOR against a bit acts as a "invert if set" gate. Apply it across a whole vector and you get "invert the whole word if `sub`".

### Why `{32{sub}}` and not just `sub`

This is the crux of the problem, and `b ^ sub` is the mistake almost everyone makes first — because it *compiles cleanly and looks right*.

`b` is 32 bits. `sub` is 1 bit. Verilog's rule for a binary bitwise operator is that both operands are first extended to the width of the wider one, and `sub` is unsigned, so it is **zero-extended**:

```
b ^ sub   ==   b ^ {31'b0, sub}
```

XOR against 31 zeros leaves those bits untouched. So `b ^ sub` inverts **only bit 0** and leaves bits 31 down to 1 exactly as they were. With `sub` set you get `b` with its LSB flipped, plus a carry-in of 1 — a result that is wrong but not obviously so, and that happens to be *correct for `b = 0`*, which is exactly the kind of near-miss that survives a casual test.

The replication operator fixes it by building an operand that is already 32 bits wide:

```
{32{sub}}   ->   sub = 0 : 32'h00000000
                 sub = 1 : 32'hFFFFFFFF
```

XOR against all-zeros is the identity; XOR against all-ones is a full complement. Now the "invert if set" behaviour applies to every bit rather than just the bottom one.

The general lesson: **broadcasting a control bit across a vector is something you must write explicitly.** Verilog will silently pad with zeros, and zero-padding is almost never the semantics you wanted for a control signal. `{32{sub}}` is the same replication operator introduced in Vector4 and Vector5 — this is its first genuinely load-bearing use in the series, where getting it wrong produces a subtly wrong number rather than an obviously wrong one.

## Gotchas / things I got wrong initially

- **`b ^ sub` inverts one bit, not thirty-two.** Covered above, and worth restating as the single most important line in the file. No warning, no width error — Verilog considers zero-extension perfectly normal. Same silent-resize family as the sized-literal lesson from Step One, but here the consequence is an arithmetic result that's wrong by an arbitrary amount.

- **Forgetting `cin = sub` gives `a + ~b`, which is `a - b - 1`.** Off by exactly one, in a way that looks like a rounding bug rather than a wiring bug. The inversion and the carry-in are two halves of one mechanism; neither works alone. Tying `cin` to `1'b0` and inverting is a classic half-implementation.

- **`{32{sub}}` versus `{{32{sub}}}` versus `{32{1'b1}}`.** The first is correct. Extra braces are harmless but noise. `{32{1'b1}}` would invert unconditionally, turning the circuit into a subtractor with no add mode — an easy slip when testing the sub path in isolation and then forgetting to put `sub` back.

- **The carry out of the top adder is still discarded.** `.cout()` — empty, never `.cout(1'b0)`. Same rule as Module_add, Module_fadd and Module_cseladd. In subtract mode this discarded bit is the borrow indicator, so a real ALU would keep it; here the spec says a 32-bit result and nothing else.

- **`wire [31:0] b_sub = b ^ {32{sub}};` is a declaration with a continuous assignment**, not a procedural initialisation. For a net this is exactly equivalent to declaring it and writing a separate `assign`, and it re-evaluates whenever `b` or `sub` changes. It is not "run once at time zero" — that reading is a C habit, and it's wrong here.

- **`assign b_sub = sub ? -b : b;` also works, and is worse hardware.** It's tempting because it states the intent directly. But `-b` synthesises to invert-plus-increment, so you pay for a 32-bit incrementer that the XOR/`cin` trick gets for free out of the adder you already have. Correct, more readable, more gates — a reasonable trade to *know about* and generally the wrong one to take in a datapath.

- **Overflow behaves as two's complement wraparound, and that's intended.** No overflow flag is requested. `a - b` for `b > a` wraps rather than saturating or erroring, which is the correct behaviour for a plain 32-bit adder/subtractor.

## Solution

See `module_addsub.v`
