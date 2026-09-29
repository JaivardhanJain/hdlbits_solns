# Alwaysblock2

**HDLBits link:** https://hdlbits.01xz.net/wiki/Alwaysblock2
**Category:** Verilog Language: Procedures
**Difficulty:** ⭐

## Problem summary

Build an XOR gate three ways: with a continuous `assign`, with a combinational `always @(*)` block, and with a clocked `always @(posedge clk)` block. The first two give identical hardware. The third adds a flip-flop, so its output arrives one clock cycle late.

## Approach

```verilog
assign out_assign = a ^ b;                        // XOR gate
always @(*)          out_always_comb =  a ^ b;    // same XOR gate
always @(posedge clk) out_always_ff  <= a ^ b;    // XOR gate -> D flip-flop
```

[Alwaysblock1](../29.%20Alwaysblock1/README.md) showed that `assign` and `always @(*)` describe the same gates. What's new here is the clocked block. The *sensitivity list* decides what hardware you get, not the `reg` keyword:

| Block | Wakes up on | Hardware |
|---|---|---|
| `assign` | any change in `a` or `b` | XOR gate |
| `always @(*)` | any change in `a` or `b` | XOR gate |
| `always @(posedge clk)` | the rising edge of `clk` only | XOR gate feeding a D flip-flop |

Here is a trace of the three outputs. `a` and `b` change between clock edges, and `out_always_ff` only picks up the value of `a ^ b` at each rising edge:

| Time | Event | `a` | `b` | `out_assign` | `out_always_comb` | `out_always_ff` |
|---|---|:-:|:-:|:-:|:-:|:-:|
| t0 | start | 0 | 0 | 0 | 0 | x |
| t1 | ↑clk | 0 | 0 | 0 | 0 | 0 |
| t2 | `a` → 1 | 1 | 0 | **1** | **1** | 0 |
| t3 | ↑clk | 1 | 0 | 1 | 1 | **1** |
| t4 | `b` → 1 | 1 | 1 | **0** | **0** | 1 |
| t5 | `b` → 0 | 1 | 0 | **1** | **1** | 1 |
| t6 | ↑clk | 1 | 0 | 1 | 1 | 1 |

The first two columns react right away. `out_always_ff` changes only on a clock edge, and it misses the short `b` pulse between t4 and t5 entirely: at t6 it sees `a ^ b = 1`, the same as before. That's what a register is for. It samples once per cycle and ignores whatever happens in between.

### Blocking (`=`) vs. non-blocking (`<=`)

Verilog has three kinds of assignment:

| Kind | Syntax | Where it's legal |
|---|---|---|
| Continuous | `assign x = y;` | outside any procedure |
| Procedural blocking | `x = y;` | inside `always` / `initial` |
| Procedural non-blocking | `x <= y;` | inside `always` / `initial` |

The two procedural kinds differ in **when the left-hand side gets its new value**:

- **Blocking `=`** updates `x` *immediately*, before the next statement runs. It works like assignment in C: later statements in the same block read the new value.
- **Non-blocking `<=`** computes the right-hand side now but *schedules* the update for the end of the time step. Every `<=` in the block reads the values from **before** the clock edge, and they all update together afterwards.

The difference matters as soon as one register feeds another. Take a 2-stage shift register, `d → q1 → q2`:

```verilog
// Non-blocking: correct
always @(posedge clk) begin
    q1 <= d;
    q2 <= q1;     // reads q1's OLD value
end

// Blocking: wrong
always @(posedge clk) begin
    q1 = d;
    q2 = q1;      // reads q1's NEW value, which is already d
end
```

Trace both with `d` = 1, 0, 1 on successive edges (both start with `q1 = q2 = 0`):

| Edge | `d` | Non-blocking `q1` | Non-blocking `q2` | Blocking `q1` | Blocking `q2` |
|:-:|:-:|:-:|:-:|:-:|:-:|
| 1 | 1 | 1 | 0 | 1 | **1** |
| 2 | 0 | 0 | 1 | 0 | **0** |
| 3 | 1 | 1 | 0 | 1 | **1** |

With `<=`, `q2` follows `d` two cycles late. That's two flip-flops, as intended. With `=`, `q2` is always equal to `q1`, so the second stage has disappeared. Synthesis agrees with the simulation and builds **one** flip-flop driving both outputs. Nothing warns you. The design is just missing a pipeline stage.

Non-blocking matches how real flip-flops work: every flop on a clock samples its D input at the same instant, and then they all change together. `<=` models that. Blocking models a chain of gates evaluated one after another, which is exactly what combinational logic is. That's where the two rules come from:

- **Clocked block → `<=`**
- **Combinational block → `=`**

The Dff chapter and the LFSRs ([Lfsr5](../../../03_circuits/sequential/shift_registers/109.%20Lfsr5/README.md) in particular) build on this rule.

## Gotchas / things I got wrong initially

- **The one-cycle lag on `out_always_ff` is the point, not a bug.** It fails HDLBits's comparison only if you expected it to match the other two outputs. A clocked block is a flip-flop, and a flip-flop shows the value it captured at the last edge. Anything that reads `out_always_ff` sees `a ^ b` *as it was one cycle ago*.

- **All three outputs are declared almost identically and the declaration tells you nothing about the hardware.** `out_always_comb` and `out_always_ff` are both `output reg`, but one is a gate and the other is a flop. Only the sensitivity list separates them. This is the [Alwaysblock1](../29.%20Alwaysblock1/README.md) lesson again: `reg` is a declaration rule, not a register.

- **`=` in a clocked block silently deletes pipeline stages.** The trace above is the whole story. It only goes wrong when one assigned value is read later in the same block, so a single-statement block like `out_always_ff = a ^ b;` gives the correct result, which is how the habit forms. Write `<=` in every clocked block, even trivial ones, so you never have to think about it.

- **Blocking assignments across *separate* clocked blocks are a simulation race.** If one `always @(posedge clk)` block writes `x = ...` and another reads `x` on the same edge, the result depends on which block the simulator runs first, and the standard doesn't say. One simulator may show a one-cycle delay while another shows none. Synthesis builds a flop either way, so hardware and at least one simulator will disagree. Non-blocking removes the race because every read sees the pre-edge value, no matter the order.

- **`<=` in a combinational block is the mirror mistake.** In `always @(*)`, if one statement computes an intermediate value with `<=` and a later one reads it, the read gets the stale value. With `@(*)` the block re-triggers when the intermediate finally updates, so it usually settles on the right answer, but only after a wasted extra pass and a momentary wrong value. With a hand-written sensitivity list that leaves out the intermediate, it stays wrong. Use `=` for combinational blocks.

- **Don't mix `=` and `<=` in one block, and don't assign one variable from two blocks.** Both make the design hard to reason about. The second is a synthesis error, because you've described two drivers on one wire.

- **Only `clk` belongs in a clocked block's sensitivity list.** `always @(posedge clk or a or b)` is neither a flip-flop nor combinational logic, and synthesis tools will reject it or build something unintended. The data inputs are sampled *at* the edge, so they don't go in the list. (The one exception is an asynchronous reset, e.g. `posedge areset` in [Dff8ar](../../../03_circuits/sequential/latches_and_flipflops/84.%20Dff8ar/README.md).)

- **`out_always_ff` is `x` until the first clock edge.** There's no reset, and the spec doesn't ask for one. For a register that only captures its input every cycle this doesn't matter, because the unknown is overwritten on the first edge. It matters once a register feeds its own value back ([Exams_m2014_q4d](../../../03_circuits/sequential/latches_and_flipflops/89.%20Exams_m2014_q4d/README.md)).

## Solution

See `alwaysblock2.v`
