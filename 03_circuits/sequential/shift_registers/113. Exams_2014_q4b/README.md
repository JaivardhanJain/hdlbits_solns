# Exams_2014_q4b

**HDLBits link:** https://hdlbits.01xz.net/wiki/Exams/2014_q4b
**Category:** Circuits: Sequential (Shift Registers)
**Difficulty:** ⭐⭐

## Problem summary

Build the 4-bit version of the shift register in the figure by instantiating four copies of the MUXDFF cell from [[Exams_2014_q4a]]. Each stage can hold, take its neighbour's value, or load a switch — and the whole thing is mapped onto DE2 board pins: `SW` is the parallel-load data `R`, `KEY[0]` is the clock, `KEY[1]` is the shift enable `E`, `KEY[2]` is the load `L`, `KEY[3]` is the serial input `w`, and `LEDR` shows `Q`.

## Approach

The problem tells you the structure outright — four copies of one cell — so the top level is nothing but wiring, and the only decisions are which net goes where.

```verilog
MUXDFF dff3 (.clk(KEY[0]), .E(KEY[1]), .L(KEY[2]), .w(KEY[3]),  .R(SW[3]), .Q(LEDR[3]));
MUXDFF dff2 (.clk(KEY[0]), .E(KEY[1]), .L(KEY[2]), .w(LEDR[3]), .R(SW[2]), .Q(LEDR[2]));
MUXDFF dff1 (.clk(KEY[0]), .E(KEY[1]), .L(KEY[2]), .w(LEDR[2]), .R(SW[1]), .Q(LEDR[1]));
MUXDFF dff0 (.clk(KEY[0]), .E(KEY[1]), .L(KEY[2]), .w(LEDR[1]), .R(SW[0]), .Q(LEDR[0]));
```

`clk`, `E` and `L` are broadcast to all four stages; only `w`, `R` and `Q` differ. The serial input `KEY[3]` enters the top stage, and each lower stage takes the stage above it, so data marches 3 → 2 → 1 → 0 and falls out the bottom. Note there are no internal wires at all: `LEDR[3]` is simultaneously dff3's output port and dff2's `w` input, which works because `LEDR` is a net.

The cell is the same one written for [[Exams_2014_q4a]], but expressed with continuous assignments rather than an `always @(*)` block:

```verilog
wire D, t;
assign t = E ? w : Q;      // enable mux: shift in w, or hold Q
assign D = L ? R : t;      // load mux: L overrides E
always @(posedge clk) Q <= D;
```

Two cascaded 2-to-1 muxes, exactly as drawn. The cascade *is* the priority encoding: `D` looks at `L` first and only falls through to `t` when `L` is low, so a simultaneous load and shift resolves as a load. The same idea as the `else if` chains in [[Shift4]] and [[Rotate100]], drawn as gates instead of written as branches.

## Gotchas / things to watch for

- **`wire D, t;` here vs. `reg t, d;` in [[Exams_2014_q4a]] — same signals, same hardware, different declaration, and the reason is *how* they're assigned, not what they are.** A signal driven by a continuous `assign` must be a net (`wire`); a signal assigned inside any procedural block, including a combinational `always @(*)`, must be a variable (`reg`). Neither form implies a flip-flop — `reg` is a storage class in the language, not a hardware register, which is the single most misleading keyword in Verilog. Both versions of MUXDFF synthesize to the identical two muxes.
- **This problem carries both `reg` rules at once, and getting either backwards is an error rather than a warning.** `Q` inside MUXDFF is `output reg` because it's assigned in the clocked block; `LEDR` at the top level must stay a plain net because it's driven by submodule output ports. Same pairing as [[Exams_m2014_q4k]]. And because `LEDR` is a net, the top level can legally *read* it back — `.w(LEDR[3])` feeds one stage's output into the next stage's input with no intermediate wire. Declare `LEDR` as `reg` out of habit and that line stops compiling.
- **The cell must be renamed relative to [[Exams_2014_q4a]], where it was `top_module`.** Module names live in one flat global namespace with no imports or scoping ([[Module_fadd]]), so you can't have two `top_module`s, and you can't "import" the earlier problem's version — you re-declare it here under a distinct name. `MUXDFF` is fine for HDLBits; in a real project a cell this generically named is a collision waiting to happen and would carry a block prefix.
- **`L` outranks `E`, and that priority lives entirely in which mux feeds which.** `assign D = L ? R : t` with `t = E ? w : Q` means load wins. Swap the two lines' roles — `t = L ? R : Q; D = E ? w : t;` — and you get a circuit where a shift beats a load, which is a legal, plausible, silently different machine. When priority is expressed as mux cascade order rather than as `if`/`else`, there's no keyword to eyeball; trace the chain from `D` backwards.
- **The "hold" case is an explicit mux input here, not an omitted branch.** In [[Shift4]] and [[Rotate100]], holding was expressed by *not* assigning — the flop keeps its value and synthesis infers a clock enable. Here the schematic draws the hold path as a real feedback wire (`E ? w : Q`), so the structural version has to state it. Both describe the same hardware; the lesson is that "no assignment" and "assign the old value back through a mux" are the same circuit, and which one you write should follow the source you're transcribing from.
- **`t = E ? w : Q` reads `Q` and ends up feeding `Q` — that's a registered loop, not a combinational one.** The path passes through the flip-flop, so it's perfectly ordinary state feedback. Worth naming because the same shape *without* the flop in the path — a signal in an `always @(*)` block that depends on itself — is a genuine combinational loop and one of the harder synthesis errors to read.
- **Four near-identical instantiation lines are exactly where a transposed net hides.** `.w(LEDR[2])` on dff1 versus `.w(LEDR[1])` is one character, and getting it wrong produces a stage that feeds itself or a broken chain — no compile error, since named connection checks port *names*, not which net you handed them ([[Module]]). Reversing the whole chain (dff0 taking `KEY[3]`) is worse: it still behaves as a shift register, just running the other way relative to the LEDs and the figure. Align the four lines in columns as above so a wrong index breaks the visual pattern, and reach for a `generate` loop ([[Vectorr]]) once the chain is long enough that reading it column-wise stops working.
- **Board realities, same as [[Mt2015_lfsr]]:** `KEY[0]` is a mechanical pushbutton being used directly as a clock (bounce gives many edges per press; a raw pin isn't on the global clock network), and DE2 `KEY`s are active-low, so at rest `E` and `L` read as asserted. None of it affects the grader, which drives `KEY[0]` as a clean clock — which is why it's worth writing down rather than assuming the reader will infer it.
- **There is no reset.** All four flops power up as `x`, and `L` — driven by a physical button — is the only way to force a known state. Shifting alone doesn't clear them: an `x` entering from `w` propagates down the chain, so the register is only as defined as what you've loaded. Same situation as [[Rotate100]] and [[Mt2015_lfsr]].

## Solution

See `exams_2014_q4b.v` — top level plus the `MUXDFF` cell it instantiates four times.
