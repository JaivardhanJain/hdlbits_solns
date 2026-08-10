# Exams/ece241_2014_q7a

**HDLBits link:** https://hdlbits.01xz.net/wiki/exams/ece241_2014_q7a
**Category:** Circuits: Sequential (Counters)
**Difficulty:** ⭐⭐⭐

## Problem summary

Build a 1-to-12 counter, but not by writing the counting logic yourself — you're given a black-box 4-bit counter, `count4`, with `enable` and synchronous parallel-`load` inputs (`load` beats `enable` when both are asserted), and the job is entirely to instantiate it and drive its inputs correctly. `d` and `load` are how you force the counter's output to a specific value instead of letting it increment.

`d` is a 4-bit input — the value you want the counter to jump to. `load` is the input that tells the counter "on the next clock edge, ignore your normal count-up behavior and take the value sitting on d instead." It's a synchronous parallel load: nothing happens the instant load goes high, the new value only lands in Q at the next posedge clk, same as everything else in this register.

Concretely, count4's internal behavior each clock edge is roughly:

```verilog
always @(posedge clk) begin
    if (load)        Q <= d;
    else if (enable)  Q <= Q + 1;
    // else: Q holds
end

```verilog
module count4 (
    input clk,
    input enable,
    input load,
    input [3:0] d,
    output reg [3:0] Q
);
```

In the top module, `reset` (synchronous) forces the counter to 1. `enable` gates whether it counts at all. Three extra outputs — `c_enable`, `c_load`, `c_d` — expose exactly what's being fed into `count4`'s control inputs, purely so the grader can check the glue logic independently of `count4`'s own (given, trusted) behaviour.

## Approach

This is the first counter in the section where you don't write `always @(posedge clk)` at all — `count4` already contains the register and the increment logic. The entire problem is combinational: figure out what `load`, `d`, and `enable` need to be, given the current state.

```verilog
assign c_enable = enable;
assign c_load   = reset || (Q == 4'd12 && enable);
assign c_d      = 4'd1;

count4 the_counter (
    .clk(clk), .enable(c_enable), .load(c_load), .d(c_d), .Q(Q)
);
```
It's important to understand that the load functionality is never used, it's just used as a reset and wrap around for the counter.

Three pieces, each doing one job:

- **`c_enable = enable`** passes the top-level enable straight through — `count4` already knows how to hold its value when `enable` is low, so there's nothing to add here.
- **`c_d = 4'd1`** is the value to load whenever a load happens. Both reasons this circuit ever loads — reset, and wrapping past 12 — land on the same value, so `c_d` can be a constant instead of a mux between "reset value" and "wrap value." 
- **`c_load = reset || (Q == 4'd12 && enable)`** is the interesting line, and it's doing the job every earlier counter in this chapter did with an `if`/`else if` chain inside its own always block — except here that chain has to be expressed as combinational logic feeding someone else's register, because you don't own the register. `reset` unconditionally requests a load (matching "reset forces the counter to 1" regardless of what `enable` happens to be — `count4`'s `load` input has priority over `enable` by construction, so this is exactly the override the spec asks for). Absent reset, a load is requested only when the counter is *currently* at the last state (12) **and** actually enabled — `Q == 4'd12 && enable`, not just `Q == 4'd12` alone, because if `enable` is low there's no reason to wrap; the counter isn't advancing this cycle at all.

The genuinely new idea here is **reading `Q` — `count4`'s own registered output — combinationally, to decide what to feed back into that same register's `load`/`d` inputs on the same clock edge.** This is precisely the terminal-count pattern from [Count10](../99.%20Count10/README.md) and [Count1to10](../100.%20Count1to10/README.md) (`if (q == 9) q <= 0`), just physically split across two modules instead of living inside one `always` block: `count4` holds the state, `top_module` holds the next-state decision logic that used to be an `if` statement and is now a `wire`. Same feedback loop, same timing — `Q` reflects last cycle's value while this combinational logic runs, and whatever `c_load`/`c_d` settle to gets captured by `count4` on the next `posedge clk` — just expressed with `assign` instead of `<=`.

## Gotchas / things to watch for

- **Forgetting the `&& enable` in the wrap condition.** `c_load = reset || (Q == 4'd12)` looks plausible and is wrong: it forces a load back to 1 the instant `Q` reaches 12, *regardless* of whether the counter is enabled — so a disabled counter sitting at 12 gets yanked back to 1 on the very next clock edge instead of holding at 12 as `enable = 0` requires. The terminal-count check has to be conjoined with the same condition that would otherwise have caused a normal increment, because a load-to-1 is standing in for "the increment that would have happened, if only 12 could be represented as 13."

- **`c_load = reset && (Q == 4'd12 && enable)`** — an easy typo, `&&` in place of the outer `||`, and it silently deletes the reset path in every case except the coincidence where the counter happens to be at 12 already. Reset stops working the moment it's needed most (an arbitrary `Q`), and there's no compile error to catch it — the module still elaborates and drives every port, it just computes a different, wrong function. Worth reading the assignment out loud as English ("load if reset, or if we're wrapping") to catch whether `||`/`&&` match the sentence.

- **Wiring `Q` to `c_d` by name-guessing instead of checking the port list.** `count4`'s ports are `clk, enable, load, d, Q` in that declared order. Positional instantiation — `count4 the_counter(clk, c_enable, c_load, c_d, Q);` — happens to work here because the port list in the problem's starter code is given in that exact order, but it's the same fragility flagged back in [Adder3](../../../combinational/arithmetic_circuits/67.%20Adder3/README.md): swap any two arguments and the compiler silently wires the wrong signal to the wrong pin, no error, just a circuit that's subtly broken. Named connections (`.clk(clk), .enable(c_enable), ...`), as used here, bind by port name regardless of declaration order and are self-documenting at the call site — the safer default whenever you're instantiating a module you didn't just write, which describes every "provided component" problem in this repo.

- **Trying to make `count4` itself count from 1–12 by feeding it a modified `d`, instead of using `load` for the wrap.** It's tempting to think "I need a 1-to-12 counter, so I should manipulate what gets counted" — but `count4` has no notion of a custom range; it only knows binary increment, enable, and load-a-specific-value. The 1–12 range is entirely a property of *when* you assert `load` and *what* you load, not anything internal to the provided counter. This is the core insight the problem is testing: composing a custom-behaviour circuit out of a fixed, unmodifiable building block by controlling its existing interface, rather than trying to reach inside it.

- **Confusing this problem's `load`-has-priority-over-`enable` counter with a from-scratch design where you'd write the priority yourself.** In every counter so far in this chapter, *you* wrote the `if (reset) ... else if (enable) ...` priority chain, so getting the order right was your responsibility. Here, `count4`'s priority (load beats enable) is a documented property of the black box, not something this module's code expresses at all — `c_load` and `c_enable` are computed independently, and it's `count4`'s internal logic, not `top_module`'s, that decides which one wins if both are asserted. Trusting (and correctly using) a documented interface contract is a different skill from implementing the priority logic directly, and it's worth noticing which one a given problem is actually asking for.

- **The `count4` module itself is not included in this repo's solution file.** Like `bcd_fadd` in [Bcdadd4](../../../combinational/arithmetic_circuits/71.%20Bcdadd4/README.md), `count4` is provided by HDLBits's grader environment, not something you write — the solution file here only defines `top_module`, and `count4`'s declaration is quoted in a comment purely for reference.

## Solution

See `exams_ece241_2014_q7a.v`
