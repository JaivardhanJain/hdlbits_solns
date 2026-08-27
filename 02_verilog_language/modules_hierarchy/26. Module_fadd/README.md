# Module_fadd

**HDLBits link:** https://hdlbits.01xz.net/wiki/Module_fadd
**Category:** Verilog Language: Modules: Hierarchy
**Difficulty:** ⭐⭐⭐

## Problem summary

The 32-bit adder from [Module_add](../25.%20Module_add/README.md), but now we also have to supply the 1-bit full adder that lives *inside* the provided `add16`. Two modules to write: `top_module` and `add1`.

## Approach

### add16 instantiates add1 in the background

This is the idea the problem exists to teach, and it inverts the pattern of every previous problem in the chapter.

Until now, the provided module was always the *child*: HDLBits handed us `mod_a` or `my_dff8`, and we wrote the parent that instantiated it. Here the design is three levels deep and we own the outer and inner layers while the given module sits in the middle:

```
top_module        <- ours
  |
  +-- add16       <- provided, body hidden from us
  |     |
  |     +-- add1  x16   <- ours
  |
  +-- add16
        |
        +-- add1  x16
```

Nothing in our code instantiates `add1`. We define it, and `add16` — whose source we never see — reaches out and instantiates sixteen copies of it internally, chaining their carries to perform its 16-bit addition. Across two `add16` instances that's 32 copies of our full adder in the elaborated design.

**Why that works: Verilog module names are global.** There is no import statement and no namespace. When the compiler elaborates `add16` and encounters `add1`, it searches every module definition in the project and binds to whichever one carries that name. Our `add1` sits as a sibling of `top_module` in the same file, so it's visible, and that's the entire linkage mechanism. It's also why the declaration must match exactly — `add16` was compiled expecting ports named `a`, `b`, `cin`, `sum`, `cout`, and connects to ours by those names.

HDLBits even documents the failure mode, and the message leaks the internals:

```
Error (12006): Node instance "user_fadd[0].a1" instantiates undefined entity "add1"
```

`user_fadd[0]` is an indexed generate-loop iteration, so `add16` uses a `generate for` to stamp out its sixteen adders, with `a1` as the instance name inside each. That's the generate idiom from Vectorr, seen from the outside for once.

### The two modules

`top_module` is unchanged from Module_add: split the operands into halves, tie the low `cin` to zero, thread `c` from the low adder's `cout` to the high adder's `cin`, discard the top carry.

`add1` computes `a + b + cin` and splits the 2-bit result:

```verilog
assign {cout, sum} = a + b + cin;
```

The concatenation on the left is 2 bits wide, and Verilog propagates that width into the right-hand side, so the sum is evaluated at 2 bits and the carry lands in `cout`. The gate-level form from HDLBits's hint (`sum = a^b^cin`, `cout = a&b | a&cin | b&cin`) is kept as a comment in the solution file — it synthesises identically, and is what you'd write if asked to build from primitives.

## Gotchas / things I got wrong initially

- **`.cout(1'b0)` is still illegal here.** Carrying the Module_add mistake forward is easy since the top-level code is otherwise identical. An output port cannot be driven by a constant — `1'b0` is not a net. Use the empty connection `.cout()`. The trap is that `.cin(1'b0)` four lines earlier is correct: constants may feed inputs, never outputs.

- **Dropping the width down to 1 bit loses the carry silently.** `assign sum = a + b + cin;` compiles and gives a correct-looking `sum`, but `cout` is then undriven and the carry between stages vanishes — every 16-bit block computes independently and the 32-bit result is wrong above bit 15. The concatenation isn't cosmetic; it's what creates the 2-bit evaluation context. Same self-determined-width thread as the sized-literal lesson from Step One.

- **`add1` must not be nested inside `top_module`.** Module definitions never nest — the point from Module (20), now with real consequences: `add1` has to be a sibling so `add16` can find it in the global namespace. Putting it before `endmodule` is a syntax error.

- **A flat global namespace is a hazard at scale.** Two files both defining `add1` gives a redefinition error, or silently picks one depending on compile order. Fine on HDLBits, dangerous in a real project, which is why production code prefixes module names by block (`alu_add1`). Worth knowing now that we've seen name-based linkage do the work invisibly.

- **The port declaration has to match byte-for-byte.** Renaming `cin` to `carry_in` makes `add1` compile perfectly on its own and breaks `add16`'s connection to it. Since we can't see `add16`'s source, the given declaration is a contract, not a suggestion — and the resulting error points at a module we didn't write, which is confusing the first time.

- **`cout` on `add1` is genuinely used, unlike `cout` on `a2`.** Both are called `cout` and it's easy to conflate them. `add1.cout` feeds the next bit's carry inside `add16`; `a2.cout` is bit 32 of a 32-bit result and has nowhere to go. Leaving `add1.cout` undriven breaks the chain quietly.

## Solution

See `module_fadd.v`
