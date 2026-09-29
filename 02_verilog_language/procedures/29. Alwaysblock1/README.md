# Alwaysblock1

**HDLBits link:** https://hdlbits.01xz.net/wiki/Alwaysblock1
**Category:** Verilog Language: Procedures
**Difficulty:** ⭐

## Problem summary

Build the same 2-input AND gate twice: once with a continuous `assign` and once with a combinational `always` block. It's the first problem in the Procedures chapter.

## Approach

The two outputs describe identical hardware:

```verilog
assign out_assign = a & b;

always @(*)
    out_alwaysblock = a & b;
```

Both re-evaluate whenever `a` or `b` changes, and both synthesize to one AND gate. The only differences are in the language:

| | `assign` | `always @(*)` |
|---|---|---|
| Left-hand side must be | a net (`wire`) | a variable (`reg`) |
| Assignment operator | `=` (continuous) | `=` (blocking, procedural) |
| Can contain `if` / `case` | no (only `?:`) | yes |

That last row is why `always @(*)` exists. For a single expression like this one, `assign` is shorter and is what you'd write in real code. Procedural blocks start to pay off once the logic needs `if`/`case` branching, which the rest of this chapter covers.

`@(*)` means "sensitive to every signal read inside the block." The tool works out the list for you, so the block wakes up on exactly the same events as the `assign`.

## Gotchas / things I got wrong initially

- **`reg` does not mean register.** `out_alwaysblock` is declared `reg` and there is no flip-flop anywhere in this design. `reg` is a *storage class* in the simulator: it holds whatever was last procedurally assigned to it. Whether hardware ends up with a flip-flop, a latch or plain gates depends on how the block is written: a clock edge in the sensitivity list gives a flop (Dff), `@(*)` with every output assigned on every path gives gates (here). This is the same rule that keeps coming back in [Mt2015_muxdff](../../../03_circuits/sequential/latches_and_flipflops/90.%20Mt2015_muxdff/README.md) and [Exams_ece241_2013_q12](../../../03_circuits/sequential/shift_registers/114.%20Exams_ece241_2013_q12/README.md). The declaration follows from *how* a signal is assigned, not from what hardware it becomes.

- **The declaration has to match the assignment style, both ways round.** Drop `reg` from `out_alwaysblock` and the procedural assignment is illegal. Add `reg` to `out_assign` and the `assign` is illegal. HDLBits normally compiles as SystemVerilog, which accepts either mistake silently, but the `// synthesis verilog_input_version verilog_2001` line at the top of the provided header switches this file to Verilog-2001, which enforces the rule. That's deliberate: it's the one place the grader makes you learn it. Keep the line.

- **Don't hand-write the sensitivity list.** `always @(a)` compiles, but in simulation the block only re-runs when `a` changes. Toggle `b` alone and `out_alwaysblock` keeps its stale value. Synthesis ignores the list, usually with only a warning, and builds a normal AND gate. So simulation and hardware now disagree, and your testbench passes or fails for the wrong reasons. `@(*)` (or `@*`, identical) can't go stale when you edit the block later. In SystemVerilog, `always_comb` is better still: it also flags a block that accidentally infers a latch.

- **Use blocking `=` in combinational blocks.** `out_alwaysblock <= a & b;` happens to simulate correctly here because there's only one statement. Once a block has intermediate values, `<=` delays them to the end of the time step and later statements read stale values. That's the mirror of the rule from [Dff](../../../03_circuits/sequential/latches_and_flipflops/80.%20Dff/README.md): `<=` for clocked blocks, `=` for combinational ones.

- **A combinational `always` block has to assign every output on every path.** This is trivially true here, since there's one unconditional statement. As soon as `if` and `case` show up, a missing `else` or an unhandled `case` value means the output must *remember* its old value, and the only way to build that without a clock is a latch. That's the main hazard of this chapter, and it comes up again in the next few problems. It's the opposite of the clocked-block rule from Shift4, where a missing `else` is a harmless hold.

## Solution

See `alwaysblock1.v`
