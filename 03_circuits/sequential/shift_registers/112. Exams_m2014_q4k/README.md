# Exams_m2014_q4k

**HDLBits link:** https://hdlbits.01xz.net/wiki/Exams/m2014_q4k
**Category:** Circuits: Sequential (Shift Registers)
**Difficulty:** ⭐⭐

## Problem summary

Build the circuit in the figure: four D flip-flops in a chain, all sharing `clk` and an active-low **synchronous** reset `resetn`. `in` feeds the first stage, `out` comes off the last, so a value entering the register appears at the output four clock cycles later. Reset drives every stage to 0 on a clock edge.

## Approach

This is the first shift register in the chapter written *structurally* — one flip-flop module instantiated four times — rather than as a single `always` block. That's a deliberate match to the figure, which draws four discrete boxes rather than a 4-bit register, and it's the same reuse idea as the MUXDFF cell in [[Mt2015_lfsr]].

The cell is one flip-flop with a synchronous, active-low clear:

```verilog
always @(posedge clk) begin
    if (~reset) q <= 0;
    else        q <= d;
end
```

and the top level is pure wiring — three internal nets carrying each stage's output to the next stage's input, with the fourth stage driving `out` directly:

```verilog
my_dff dff0 (.clk(clk), .reset(resetn), .d(in),   .q(t[0]));
my_dff dff1 (.clk(clk), .reset(resetn), .d(t[0]), .q(t[1]));
my_dff dff2 (.clk(clk), .reset(resetn), .d(t[1]), .q(t[2]));
my_dff dff3 (.clk(clk), .reset(resetn), .d(t[2]), .q(out));
```

Named port connections throughout, per [[Module]] — with four near-identical instantiation lines differing only in which net appears where, positional connection would make a transposed argument invisible.

The behavioural equivalent — kept alongside as `alt1.v` — collapses all of that into one clocked block:

```verilog
reg [3:0] sr;
always @(posedge clk) begin
    if (~resetn) sr <= 0;
    else         sr <= {sr[2:0], in};   // shift up; "in" enters at the LSB
end
assign out = sr[3];
```

Identical hardware, and the two files are worth reading side by side. The structural version mirrors the drawing and makes the per-stage cell reusable; the behavioural version is shorter, scales to 40 stages without 40 lines, keeps the register in one named object you can watch as a bus in a waveform, and has no internal net names to transpose. Production RTL almost always takes the second form for a plain shift register and reserves explicit instantiation for cells that genuinely differ from one another.

Note that `alt1.v` shifts *up* — `in` enters at `sr[0]` and exits from `sr[3]` — which is the opposite index direction from the shifters earlier in this chapter but the same direction as [[Mt2015_lfsr]]. Nothing forces the choice; what forces it is that `out` must then be `sr[3]`, the end furthest from the input. Getting the pair inconsistent (`{in, sr[3:1]}` with `out = sr[3]`) gives a one-cycle delay instead of four, and no error.

## Gotchas / things to watch for

- **`wire t[2:0];` is an *unpacked array* of three 1-bit nets, not a 3-bit vector — the brackets are on the wrong side of the name.** A 3-bit vector is `wire [2:0] t;` (size before the name); putting the range *after* the name declares an array of separate nets. It compiles and works here only because every use is a single-element index, which is all a net array supports for port connection. What you lose is everything that makes a vector a vector: `t[2:0]` as a part select, `{t, in}` in a concatenation, assigning it as a unit, or seeing it as one bus in a waveform viewer are all illegal or meaningless. Change one line to use a slice later and you get a confusing error in code that has "always worked." The two forms look so alike that this is easy to type and easy to read past — write `wire [2:0] t;` unless you specifically want an array.
- **`my_dff`'s port is named `reset` but carries an active-low signal — the interface lies about its own polarity.** The inversion lives *inside* the cell (`if (~reset)`), so the module's contract is "assert this port LOW to reset," which its name says the opposite of. Anyone reusing `my_dff` and wiring a normal active-high reset to `.reset(rst)` gets a circuit that resets exactly when it shouldn't, and nothing flags it — port *names* are checked, port *meanings* aren't. The industry convention exists precisely for this: an active-low signal carries an `_n` or `n` suffix (`reset_n`, `resetn`, `rst_n`) at every level it passes through, so the polarity travels with the name. Renaming the port to `resetn` would make the instantiations read `.resetn(resetn)` and the mismatch impossible.
- **The reset is synchronous, and only the sensitivity list says so.** `if (~reset)` inside `always @(posedge clk)` with no `posedge reset` in the list is a synchronous clear — the reset input is sampled at the clock edge like `d`. This is the same line of code that would be an *asynchronous* reset in [[Shift4]]; nothing but the sensitivity list distinguishes them. A synchronous reset also means a reset pulse narrower than a clock period can be missed entirely.
- **`out` must NOT be declared `reg` here — this is the converse of the rule from the last few problems.** [[Lfsr5]] and [[Mt2015_lfsr]] needed `output reg` because the output was assigned procedurally. Here `out` is driven by `dff3`'s output port, which makes it a net; declaring it `reg` would be an error (a variable can't be driven by a port connection). The rule isn't "outputs of sequential circuits are `reg`" — it's "outputs assigned in a procedural block are `reg`, outputs driven structurally are not." Same distinction that came up in Module_shift and Module_add.
- **`q <= 0;` should be `q <= 1'b0;`.** An unsized `0` is a 32-bit literal that gets truncated to fit — harmless for a 1-bit flop, and the exact habit that [[Step One]] flags, because the same reflex on a wider target is where real width bugs come from. Similarly `if (~reset)` uses the bitwise NOT where the logical `!reset` expresses "is this signal false" more precisely; on a 1-bit signal they're identical, on a vector they are not (see [[Norgate]]).
- **`my_dff` is a very generic name in a flat global namespace.** Verilog has no imports or scoping for module names — the compiler binds `my_dff` across the entire project, so two files each defining their own `my_dff` collide at elaboration, not at authoring time ([[Module_fadd]]). In production this is why cells get a block prefix (`shiftreg_dff`, `mem_dff`). It matters more than usual for a helper this small and this tempting to redefine.
- **Four instantiation lines that differ in one token each are exactly where a transposition hides.** `.d(t[1]), .q(t[2])` versus `.d(t[2]), .q(t[1])` is a one-character difference that produces a combinational loop or a stuck stage rather than a compile error. Named connection (used here) protects against wrong port *names*, not against the right names carrying the wrong nets — that's the limit of the [[Module]] lesson. When a chain gets long enough for this to be a real risk, a `generate` loop ([[Vectorr]]) removes the repetition and the class of typo with it.
- **In `alt1.v`, `out` is a wire driven by `assign` — and `sr` is the `reg`.** The same rule as above from the other direction: the *register* is `reg [3:0] sr` because it's assigned procedurally, while `out` stays a plain output because a continuous assignment drives a net. A single `output reg out` with `out <= sr[2]` inside the block would also work but adds a fifth flip-flop and a fifth cycle of latency — a subtly different circuit, not a stylistic variant.
- **`sr <= 0;` on a 4-bit register is the [[Step One]] habit at slightly higher stakes than `q <= 0` on a 1-bit flop.** It happens to be right, because an unsized `0` is all zeros however wide it gets truncated. `4'b0` states the width and makes a later change from "clear" to "preset" (`4'b1010`) a one-token edit rather than a rewrite.
- **Remember the four-cycle latency when reading the waveform.** `out` is not a function of the current `in`; it's `in` from four edges ago. Debugging a shift register by lining up `in` and `out` on the same time slice is a common way to convince yourself a correct circuit is broken.

## Solution

- `exams_m2014_q4k.v` — structural: top level plus the `my_dff` cell it instantiates four times.
- `alt1.v` — behavioural: the same circuit as one clocked block over a 4-bit register.
