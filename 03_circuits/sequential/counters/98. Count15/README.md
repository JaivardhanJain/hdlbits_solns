# Count15

**HDLBits link:** https://hdlbits.01xz.net/wiki/count15
**Category:** Circuits: Sequential (Counters)
**Difficulty:** ⭐⭐

## Problem summary

Build a 4-bit binary counter that runs 0 → 15 and then rolls back to 0, i.e. a period of 16. A synchronous active-high `reset` forces the count back to 0 on the next rising clock edge.

## Approach

This is the first problem in the Counters chapter, and it's deliberately the easiest one: a counter is just a register whose next value is its own current value plus one. Everything needed was already established in the flip-flop chapter — `always @(posedge clk)`, non-blocking `<=`, and the synchronous-reset shape from [Dff8r](../../latches_and_flipflops/82.%20Dff8r/README.md):

```verilog
always @ (posedge clk) begin
    if (reset) q <= 4'd0;
    else       q <= q + 4'd1;
end
```

Two things make this shorter than it looks:

**The wraparound is free.** Nothing in the code says "stop at 15." `q` is 4 bits wide, so `4'd15 + 4'd1` = `4'b1111 + 4'b0001` = `4'b0000` — the carry out of bit 3 has nowhere to go and is simply discarded. Every N-bit register that increments is automatically a mod-2^N counter. This only works because the required period (16) happens to be exactly 2^4; the very next problem in the chapter (Count10, period 10) is the one that forces you to add an explicit rollback, because 10 is not a power of two.

**`q` appears on both sides of the assignment, and that's fine here.** Reading a signal you're also writing inside a clocked block is exactly what non-blocking assignment is for: the right-hand side is evaluated using the *old* (pre-edge) value of `q`, so `q <= q + 1` means "next `q` = current `q` + 1" rather than an impossible self-referential loop. In hardware this synthesizes to a 4-bit incrementer feeding the register's D inputs, with the register's Q outputs feeding back into it — the same feedback shape first seen in [Exams_m2014_q4d](../../latches_and_flipflops/89.%20Exams_m2014_q4d/README.md), where a flop was XORed with its own output.

**Reset is synchronous**, so `reset` stays out of the sensitivity list — `always @(posedge clk)` only, never `always @(posedge clk or posedge reset)`. As established in [Dff8ar](../../latches_and_flipflops/84.%20Dff8ar/README.md), the sensitivity list is the *only* place a synchronous and an asynchronous reset differ in Verilog; the body of the block looks identical either way.

## Gotchas / things to watch for

- **Width-mismatched literals: `q <= 3'b0` / `q + 3'b1` into a 4-bit `q`.** This is the easiest mistake to make here, and the cruellest, because *it still works*. The zero zero-extends to `4'b0000`, and in `q + 3'b1` the addition is performed in the context of the 4-bit assignment target, so the `3'b1` is widened to `4'b0001` before adding. The counter counts correctly and HDLBits passes it — but the code now claims a 3-bit intent for a 4-bit signal, and the next reader has to re-derive the width rules to convince themselves it isn't a bug. Worse, the same typo *is* a real bug the moment the expression isn't directly assigned to a wide enough target (e.g. inside a concatenation, where operand widths are self-determined and no widening happens). Write literals at the width of the signal they touch: `4'd0` and `4'd1`. This is the same sized-vs-unsized-literal discipline introduced back in [Step One](../../../../01_getting_started/) and repeated through the vector chapter — the fact that it's *silently* forgiving here is precisely why it's worth flagging.

- **Blocking `=` instead of non-blocking `<=` in a self-referencing counter.** `q = q + 4'd1` inside a clocked block will simulate correctly in isolation, so it looks harmless. It stops being harmless the moment anything else in the design reads `q` from another always block on the same edge: with blocking assignment, whether that reader sees the old or the new count depends on the simulator's arbitrary ordering of the two blocks — a genuine race, and a class of bug that reproduces on one tool and not another. A counter is one of the most-read signals in a typical design, so it's an unusually bad place to introduce it. Rule stands from [Dff](../../latches_and_flipflops/80.%20Dff/README.md): `<=` for everything clocked, `=` for everything combinational.

- **Adding an explicit wrap that you don't need.** A very common first instinct is `if (q == 4'd15) q <= 4'd0; else q <= q + 4'd1;`. It's functionally correct, but it asks the synthesis tool to build a 4-input equality comparator and a mux that duplicate work the incrementer's discarded carry already does for free — more logic, an extra level of delay in the counter's feedback path, for identical behaviour. Reach for an explicit terminal-count comparison only when the period genuinely isn't a power of two (Count10, Count1to10, the BCD counters later in this chapter all need it). Knowing *when* natural wraparound suffices is the actual lesson of this problem.

- **`output [3:0] q` without `reg` is Verilog-2001-illegal, even though HDLBits accepts it.** HDLBits compiles as SystemVerilog, where an undeclared output defaults to `logic` and can be assigned procedurally, so `output [3:0] q` plus an `always` block passes the grader. Feed the same file to a strict Verilog-2001 flow and it's an error: a signal assigned inside an `always` block must be a variable (`reg`). Declare `output reg [3:0] q` — it costs one word, it's correct under both standards, and it documents that `q` is register state rather than combinational output. (In a SystemVerilog codebase, `output logic [3:0] q` is the modern equivalent; `logic` is the preferred type for both, which is part of why SystemVerilog dropped the `wire`/`reg` distinction that trips people up.)

- **`q` starts as `x`, not 0, and the testbench relies on reset to fix it.** There is no `initial` block and no power-on value — before the first `reset`, `q` is unknown, and `x + 1` is still `x`, so an unreset counter stays `x` forever rather than eventually counting. This is the same simulation trap as the self-feedback flop in [Exams_m2014_q4d](../../latches_and_flipflops/89.%20Exams_m2014_q4d/README.md), and the same fix applies: the reset is what makes the circuit's state defined, so it's a functional requirement rather than a convenience. (Some FPGA families do initialize registers from the bitstream at configuration time, but relying on that makes the design non-portable and untestable in simulation.)

- **"Counts from 0 through 15 inclusive" is a period, not a range check.** Nothing constrains `q` to stay inside 0–15 — it *can't* leave, because it's 4 bits wide. Reading the spec as a bound to enforce (rather than a consequence of the width) is what leads to the unnecessary comparator above. The width is the specification.

## Solution

See `count15.v`
