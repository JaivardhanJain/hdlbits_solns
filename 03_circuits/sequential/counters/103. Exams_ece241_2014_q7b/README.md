# Exams/ece241_2014_q7b

**HDLBits link:** https://hdlbits.01xz.net/wiki/exams/ece241_2014_q7b
**Category:** Circuits: Sequential (Counters)
**Difficulty:** ⭐⭐⭐

## Problem summary

From a 1000 Hz clock, derive `OneHertz` — a signal that pulses high for exactly one clock cycle out of every 1000, i.e. once per second. You're given a modulo-10 (BCD) counter, `bcdcount`, with synchronous `reset` and an `enable` (counts only while high):

```verilog
module bcdcount (
    input clk,
    input reset,
    input enable,
    output reg [3:0] Q
);
```

Build the divide-by-1000 using three of these, plus "as few other gates as possible," and also expose each counter's own `enable` signal as `c_enable[2:0]` (`c_enable[0]` = fastest counter, `c_enable[2]` = slowest) so the grader can check the enable logic directly.

## What BCD is, briefly

BCD (binary-coded decimal) represents a number as one 4-bit binary group per *decimal digit*, instead of one binary value for the whole number. A `bcdcount` doesn't count 0 → 15 like a plain 4-bit binary counter — it counts 0 → 9 and wraps, because it's built (internally, as a black box here) to represent exactly one decimal digit: `0000` through `1001`, never touching `1010`–`1111`. This is the same BCD idea introduced in [Bcdadd4](../../combinational/arithmetic_circuits/71.%20Bcdadd4/README.md), just on the counting side instead of the adding side: there, four BCD *adders* were chained to add two 4-digit decimal numbers digit-by-digit; here, three BCD *counters* are chained to count a 3-digit decimal number (000–999) digit-by-digit. Same reason in both cases — decimal digits map onto human-readable output (seven-segment displays, clock faces) far more directly than raw binary ever would.

## Approach: three digits, a ripple-carry enable chain

```verilog
wire [3:0] Q [2:0];   // Q[0] = ones digit, Q[1] = tens digit, Q[2] = hundreds digit

assign c_enable[0] = 1'b1;
assign c_enable[1] = (Q[0] == 4'd9);
assign c_enable[2] = (Q[1] == 4'd9) && c_enable[1];
assign OneHertz     = (Q[2] == 4'd9) && (Q[1] == 4'd9) && (Q[0] == 4'd9);

bcdcount counter0 (.clk(clk), .reset(reset), .enable(c_enable[0]), .Q(Q[0]));
bcdcount counter1 (.clk(clk), .reset(reset), .enable(c_enable[1]), .Q(Q[1]));
bcdcount counter2 (.clk(clk), .reset(reset), .enable(c_enable[2]), .Q(Q[2]));
```

Think of `Q[2]Q[1]Q[0]` as one 3-digit decimal number, 000 through 999 — a "digital odometer." An ordinary odometer's ones wheel turns every tick; the tens wheel only turns when the ones wheel is about to roll from 9 back to 0; the hundreds wheel only turns when *both* the ones and tens wheels are about to roll over together. That's exactly the enable chain above:

- **`c_enable[0] = 1'b1`** — the ones digit (`Q[0]`) is enabled every single 1000 Hz tick. It's the fastest-moving digit, counting 0→9→0→9... continuously, once per input clock cycle.

- **`c_enable[1] = (Q[0] == 4'd9)`** — the tens digit only advances on the tick where the ones digit is *currently* 9 (and therefore is about to wrap to 0 on this same edge). That's precisely the moment a real decimal counter would carry into the tens place: ones goes 9→0, tens goes up by one, simultaneously, on the same clock edge. Every counter tracks its own terminal-count condition, and `c_enable[1]` is just that condition, read off `Q[0]`, wired out as the *next* digit's permission to count.

- **`c_enable[2] = (Q[1] == 4'd9) && c_enable[1]`** — this is the one line that isn't a direct copy of the previous line, and it's the crux of the exercise. It's tempting to write `c_enable[2] = (Q[1] == 4'd9)` alone, by analogy with `c_enable[1]`, but that's wrong: the tens digit sitting at 9 only means "the *next* time the tens digit increments, it will wrap." It says nothing about whether the tens digit is incrementing *this* cycle at all — that's what `c_enable[1]` (the tens digit's own enable) tells you. Only when **both** are true — tens is at 9, *and* tens is actually about to increment this edge — does the hundreds digit also need to increment. This is a ripple-carry: each stage's "carry out" is gated by both "am I at my terminal value" and "did I actually just get a carry in," chained backward exactly like a ripple-carry adder's `cout` chain (see [Adder3](../../combinational/arithmetic_circuits/67.%20Adder3/README.md)) — except the "carry" here is an enable pulse propagating from fast digit to slow digit instead of a sum bit propagating from low bit to high bit.

- **`OneHertz = (Q[2]==9) && (Q[1]==9) && (Q[0]==9)`** — asserted for exactly the one cycle where the count reads 999, i.e. the cycle immediately before it rolls back to 000. Because `bcdcount`'s `Q` only changes on a clock edge, this condition is true for exactly one full 1000 Hz clock period out of every 1000 — which is exactly the "asserted for exactly one cycle each second" the spec asks for, with no separate pulse-shaping logic needed. The count reaching 999 *is* the one-second boundary; `OneHertz` just names that moment.

**Why "as few other gates as possible" matters here:** the whole design is three `bcdcount` instances plus four two/three-input gates (the `c_enable[1]`, `c_enable[2]`, and `OneHertz` equations) — no separate binary-to-BCD conversion, no extra comparators against 999 built some other way, no additional counter tracking "how many ticks total." The BCD structure and the ripple-enable chain together *are* the divide-by-1000; there's nothing left to add.

## Gotchas / things to watch for

- **`c_enable[2] = (Q[1] == 4'd9)` without `&& c_enable[1]` — the headline bug.** This makes the hundreds digit increment every time the tens digit merely *reads* 9, regardless of whether the tens digit is actually about to change. Since `Q[1]` sits at 9 for ten full ticks in a row before it finally wraps (waiting on `c_enable[1]`), the hundreds digit would increment on every one of those ten ticks instead of just the one where the tens digit genuinely rolls over — the count would run far too fast and stop being a valid 3-digit decimal sequence at all. This is the direct BCD-counter analogue of forgetting the incoming-carry term in a ripple-carry adder's carry-out logic.

- **Declaring `Q` as `reg [3:0] Q [2:0]` inside `top_module`, as the original draft did.** Two problems with this, stacked: first, `Q` here is driven entirely by `assign`-free continuous connections from three `bcdcount` instances' output ports — nothing in `top_module` ever assigns it inside an `always` block or with a blocking/non-blocking assignment, so it must be declared `wire`, not `reg`. `reg` is reserved for signals assigned procedurally; a signal that's only ever the target of a module output port connection is a net. (This is the same `wire`-vs-`reg` distinction as [Mt2015_muxdff](../../latches_and_flipflops/90.%20Mt2015_muxdff/README.md), just showing up on a hierarchical connection instead of a procedural one.) Second — and this is the one worth internalizing from [Bcdadd4](../../combinational/arithmetic_circuits/71.%20Bcdadd4/README.md) — `[3:0] Q [2:0]` with the second index *after* the name is an **unpacked array** of three independent 4-bit nets (`Q[0]`, `Q[1]`, `Q[2]`), not a single packed 12-bit vector. That's the right call here too, for the same reason as the BCD adder's carry array: the three digits are never read, compared, or manipulated together as one combined value — only individually, or pairwise in the enable chain — so there's no packed relationship to declare.

- **Wiring the three `bcdcount` instances positionally.** `bcdcount counter0(clk, reset, c_enable[0], Q[0]);` works only because the port order (`clk, reset, enable, Q`) happens to match the call site exactly — the same fragility flagged for `count4` in [Exams_ece241_2014_q7a](../102.%20Exams_ece241_2014_q7a/README.md). Named connections (`.clk(clk), .reset(reset), .enable(c_enable[0]), .Q(Q[0])`) cost a few extra characters and are immune to the port list ever being reordered or misremembered.

- **Confusing the counters' shared `reset` with a way to make each digit reset independently, or wiring `reset` to only one counter.** All three `bcdcount` instances take the *same* `reset` signal — the whole 3-digit number needs to reset to 000 together, not digit-by-digit, and there's no requirement (or mechanism given) for resetting one digit without the others. It's easy to only notice `reset` needs wiring to `counter0` while copy-pasting the instantiation lines and forget it on `counter1`/`counter2`; each of the three instances needs `reset` connected identically.

- **`Q[0] == 9` (unsized literal) instead of `Q[0] == 4'd9`.** Same width-hygiene note as every counter in this chapter — works here because both operands still compare correctly after the usual context-based widening, but it's worth being consistent: this file compares a 4-bit BCD digit against a value that can only ever be a valid decimal digit (0–9), and `4'd9` says that directly.

- **Treating this as "just a mod-1000 binary counter" and reaching for a single wide register with a `== 999` comparator**, rather than three chained mod-10 counters. It would functionally also produce a 1-second pulse, but it throws away the entire point of the exercise (BCD digit counters cascading via ripple-enable) and — worse for a real design — a single 10-bit binary counter's value isn't directly displayable on three decimal digits the way `Q[2]Q[1]Q[0]` already is; you'd need a binary-to-BCD converter afterward to drive a seven-segment clock display, which is exactly the extra hardware "as few other gates as possible" is steering you away from needing.

## Solution

See `exams_ece241_2014_q7b.v`
