# Exams_ece241_2014_q4

**HDLBits link:** https://hdlbits.01xz.net/wiki/exams/ece241_2014_q4
**Category:** Circuits: Sequential (Latches and Flip-flops)
**Difficulty:** ⭐⭐⭐⭐

## Problem summary

Build a given 3-flip-flop FSM circuit from its schematic. Each flip-flop is built from a provided `my_dff` submodule that exposes both `q` and its complement `notq`. The problem statement adds one explicit condition: *"assume that the D flip-flops are initially reset to zero before the machine begins"* — even though the module interface (`clk`, `x` only) has no reset pin to express that with.

## Approach

The next-state logic itself is straightforward once read off the schematic — one XOR-toggle stage and two stages gated by the *complement* of the previous state:

```verilog
assign t0 = x ^ t1;    // d0 = x XOR q0
assign t2 = x & t4;    // d1 = x AND notq1
assign t5 = x | t7;    // d2 = x OR  notq2
assign z  = ~(t1 | t3 | t6);
```

`t1`, `t3`, `t6` are the three flops' `q` outputs; `t4`, `t7` are `dff1`/`dff2`'s `notq` outputs, used directly as the schematic shows.

The interesting part of this problem isn't the next-state logic, it's making `notq` trustworthy — three earlier attempts on this exact circuit failed for three different reasons, and the fix here is to solve the actual problem rather than avoid it.

### Why the naive version is broken

```verilog
module my_dff (
    input clk, input d,
    output reg q, output reg notq
);
    always @(posedge clk) begin
        q    <= d;
        notq <= ~d;
    end
endmodule
```

`q` and `notq` are two *independent* registers that only happen to agree because they're always fed complementary data — from the first clock edge onward. That says nothing about their power-up values. HDLBits's grader compiles through Quartus, which models an un-reset flip-flop the way real FPGA silicon behaves: it settles to a real, defined value (0) from the configuration bitstream, not the `x`-forever an ordinary RTL testbench would show. That happens to *both* registers independently, since Quartus has no way to know `notq` is "supposed to" track `q`'s complement. Before the first clock edge, `q=0` **and** `notq=0` at the same time — not actually inverses, exactly what HDLBits's own hint is warning about ("ensure not_q really is the inverse of q, even before the first clock edge"). The very first real transition is then computed from a `notq` that's silently wrong, and the error propagates through every state after it.

### The fix used here: reset the pair at the source

```verilog
module my_dff (
    input clk, input d,
    output reg q, output reg notq
);
    initial begin
        q    = 1'b0;
        notq = 1'b1;
    end
    always @(posedge clk) begin
        q    <= d;
        notq <= ~d;
    end
endmodule
```

One `initial` block, placed **inside `my_dff` itself**, forcing the true complementary pair (`0`/`1`) before any clock edge. This is the direct fix: it doesn't work around the untrustworthy `notq`, it makes `notq` trustworthy, which means `top_module` can use `t4`/`t7` exactly as the schematic shows, with no rewriting of the next-state logic needed. `alt1.v` shows the alternative — never use the submodule's `notq` at all, and derive the complement combinationally (`~t3`, `~t6`) wherever it's needed, so there's no register to reset in the first place. Both are legitimate; see the gotchas below for the trade-off.

### Two things that look like fixes but aren't

- **`initial` from *inside* `top_module`, targeting the wires:**
  ```verilog
  initial begin
      assign q = {0, 0, 0};
      assign not_q = {1, 1, 1};
  end
  ```
  This aims at the right problem but from the wrong place, two ways at once. `assign` inside an `initial`/`always` block is a *procedural continuous assignment* — a different, legacy construct from the `assign` you already know, unsupported by Quartus for synthesis at all (the literal compile error it throws: *"Procedural Continuous Assignment to register is not supported"*). And even with correct syntax, `q`/`notq` at the `top_module` level are wires driven by the `my_dff` instances' output ports — you cannot assign an initial value to a net from outside the module whose internal register actually drives it. A submodule's reset state can only be set inside that submodule.

- **Reverting to `t4`/`t7` without re-adding the `initial` block.** If the reset gets dropped from `my_dff` while `top_module` still wires up `t2 = x & t4; t5 = x | t7;`, this is silently the exact same broken circuit as the naive version above — same bug, just spelled with named wires instead of generic ones. The `notq` port itself isn't the problem; using it *unreset* is.

## Gotchas / things to watch for

- **A dedicated "Q̄" output on a flip-flop is not automatically guaranteed to equal `~Q` when neither pin has a reset.** In real hardware, `Q` and `Q̄` come from the same bistable element and are physically forced complementary by construction. In this RTL model, `q` and `notq` are two independent always-block assignments that only agree from the first clock edge onward — an invariant that says nothing about their power-up values. Whenever a "complement" output is implemented as its own register, ask whether its reset state is actually tied to the signal it's supposed to mirror. Here, it wasn't, until the `initial` block made it so.
- **Fixing the register at its source vs. avoiding the register entirely are both valid, with a real trade-off.** This solution resets `notq` inside `my_dff`, so the submodule genuinely does what its interface promises — any future caller of `my_dff` gets a trustworthy `notq` for free, which matters if this module gets reused elsewhere. `alt1.v` instead never uses `notq` and derives `~q` combinationally at each call site, which needs no reset anywhere but pushes the "don't trust notq" knowledge onto every caller instead of fixing it once. Resetting at the source is generally the better default for a reusable submodule; deriving combinationally is reasonable when you don't control the submodule and can't add a reset to it.
- **`assign` inside `initial`/`always` is a different construct from the `assign` you already know, and it's a trap precisely because it looks identical.** The continuous `assign` outside any procedural block drives a `wire` forever. The *procedural* form inside `initial`/`always` forces a value onto a `reg` temporarily and is a simulation-era construct essentially no modern synthesis tool supports. If you're inside a procedural block and want to set a variable's starting value, that's a plain `q = 1'b0;`, not `assign q = 1'b0;`.
- **You can't set a submodule's reset state from the outside.** `top_module` only sees `my_dff`'s ports; it has no access to the register that actually holds the state. If a submodule needs a particular power-up value, that has to be built into the submodule itself.
- **Read "assume reset to zero" as telling you what to *build*, not what Verilog gives you for free.** A bare `reg` in a plain RTL simulator defaults to `x`; this problem is graded against a synthesis-flavoured model where an un-reset flop instead settles to a real hardware power-up value of 0 — and that default applies independently to *every* un-reset register, including ones (like `notq`) that are supposed to track another signal. Either build hardware that actually reaches the assumed state (an `initial` block, as here, or a real reset input), or structure the logic so the assumption holds regardless (`alt1.v`'s approach).
- **`initial` blocks are for setting real starting state, and this is one of the rare RTL cases where that's the correct tool.** Contrast with [[Exams_m2014_q4d]], where adding an `initial` was flagged as the *wrong* fix because that circuit had no specified reset behaviour at all. Here, the problem statement explicitly specifies a reset-to-zero starting condition with no reset pin to express it through — `initial`, placed at the actual register, is exactly the right mechanism.

## Solution

See `exams_ece241_2014_q4.v` (reset `notq` at the source inside `my_dff`) and `alt1.v` (never trust `notq`; derive the complement combinationally instead).
