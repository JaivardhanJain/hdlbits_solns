# Always_if2

**HDLBits link:** https://hdlbits.01xz.net/wiki/Always_if2
**Category:** Verilog Language: Procedures
**Difficulty:** ⭐⭐

## Problem summary

HDLBits gives a module with two combinational `always` blocks. Each contains an `if` with no `else`, so both outputs infer latches. Fix it so the circuit is purely combinational:

- `shut_off_computer` is 1 when the CPU is overheated, and 0 otherwise.
- `keep_driving` is 1 while we haven't arrived *and* the tank isn't empty. Once we've arrived, it's 0.

## Approach

The provided code:

```verilog
always @(*) begin
    if (cpu_overheated)
       shut_off_computer = 1;           // ...and when it's not overheated?
end

always @(*) begin
    if (~arrived)
       keep_driving = ~gas_tank_empty;  // ...and once we've arrived?
end
```

The question to ask of every combinational block is **"what should each output be in the cases I didn't write?"** Here the spec answers it: 0 in both cases. So each block gets an `else` that assigns 0, and every output is now assigned on every path through its block.

### How an `if` ends up building a latch

A combinational `always` block describes a function: every output is computed purely from the current inputs. Verilog doesn't require you to assign every output in every branch, though. When a branch doesn't assign a variable, that variable **keeps its previous value**. In simulation it's just a `reg` that wasn't written. In hardware, "keep the previous value" means storage, and since there's no clock in the block, the only storage the tool can build is a **level-sensitive latch**.

Here's what synthesis builds for the buggy `keep_driving`:

```
                  +---------+
~gas_tank_empty ->| D     Q |----> keep_driving
                  |         |
       ~arrived ->| EN      |      EN = 1 : transparent, Q follows D
                  +---------+      EN = 0 : opaque, Q holds its last value
```

The `if` condition became the latch's enable, and the assigned expression became its D input. A cycle-by-cycle trace shows the bug:

| Step | `arrived` | `gas_tank_empty` | Buggy `keep_driving` | Fixed `keep_driving` |
|:-:|:-:|:-:|:-:|:-:|
| 1 | 0 | 0 | 1 | 1 |
| 2 | 0 | 1 | 0 | 0 |
| 3 | 0 | 0 | 1 | 1 |
| 4 | **1** | 0 | **1** (held: still driving after arriving) | 0 |
| 5 | 1 | 1 | **1** (still held) | 0 |

`shut_off_computer` is worse. Once the CPU overheats even once, the latch captures 1 and the output **never** goes back to 0 until power is cycled. The computer stays shut off permanently.

Nothing about this is an error. The code compiles, simulates, and synthesizes. The only sign is a warning, which Quartus words as `Warning (10240): ... inferring latch(es) for variable "keep_driving"`. Unless you meant to build a latch, that warning is always a bug.

### Why accidental latches are a problem

- **Wrong behaviour.** The circuit remembers things the spec says it should forget (see the trace above).
- **Timing analysis gets much harder.** A flip-flop samples once, at a clock edge. A latch is transparent for the whole time its enable is high, so paths run *through* it. Static timing tools either handle this poorly or report it as a violation, and designers often can't tell whether the timing is actually met.
- **Glitches get captured.** The enable here is ordinary combinational logic (`~arrived`), not a clean clock. A brief glitch on the enable can open the latch and store whatever D happened to be at that moment.
- **FPGAs mostly don't have latches.** Many FPGA fabrics build a latch out of a LUT that feeds its own output back in. That's a combinational loop, which timing tools flag and which can behave unpredictably.
- **No reset, and poor testability.** An accidental latch has no reset, so it can power up holding anything. It also doesn't fit into the scan chains used to test chips after manufacturing.

Real designs do use latches deliberately in a few places, such as clock gating and some high-speed pipelines. There they're intentional and constrained, which accidental ones aren't. [Exams_m2014_q4a](../../../03_circuits/sequential/latches_and_flipflops/86.%20Exams_m2014_q4a/README.md) is the one problem in this set that asks for a latch on purpose.

## Gotchas / things I got wrong initially

- **`@(*)` does not stop latches.** It only makes sure the block re-runs whenever an input changes. Whether you get a latch depends on whether every output is assigned on every path, which is a completely separate question. A block can have a perfect sensitivity list and still infer a latch. SystemVerilog's `always_comb` doesn't prevent latches either, but tools report an error or warning when an `always_comb` block infers one, which is why it's preferred.

- **Writing `else keep_driving = keep_driving;` is still a latch.** It looks like it closes the gap, but it describes exactly the same "hold the old value" behaviour, just written out. The only fix is an `else` that computes a value from the inputs.

- **Every output in the block has to be covered, not just one.** These two outputs are in separate blocks, so each block only has one output to worry about. In a block that assigns several outputs, a branch that sets `x` but forgets `y` gives you a latch on `y` alone. The default-assignment idiom from [Always_if](../31.%20Always_if/README.md) removes that risk:

  ```verilog
  always @(*) begin
      keep_driving = 1'b0;                              // default for every path
      if (~arrived) keep_driving = ~gas_tank_empty;     // override when it applies
  end
  ```

- **Missing `else` means a latch only in a *combinational* block.** In a clocked block (`always @(posedge clk)`), an unassigned branch is just a flip-flop holding its value, which is the clock-enable behaviour used on purpose in [Shift4](../../../03_circuits/sequential/shift_registers/106.%20Shift4/README.md) and [Countslow](../../../03_circuits/sequential/counters/101.%20Countslow/README.md). The same code shape is a bug in one kind of block and a feature in the other.

- **An `if`/`else` that picks between constants 1 and 0 is just the condition.** `if (cpu_overheated) x = 1; else x = 0;` is the same as `x = cpu_overheated;`, a plain wire with no logic at all. Keeping the `if`/`else` makes the before-and-after fix easy to compare with the buggy code, which is the point of this problem. Outside of this exercise, the one-line assignment is clearer.

- **`case` statements without a `default` fail the same way.** An unhandled `case` value is the same as a missing `else`, and it infers a latch for the same reason. The upcoming `case` problems in this chapter come back to it.

## Solution

See `always_if2.v`
