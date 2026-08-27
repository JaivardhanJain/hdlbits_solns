# Mt2015_lfsr

**HDLBits link:** https://hdlbits.01xz.net/wiki/Mt2015_lfsr
**Category:** Circuits: Sequential (Shift Registers)
**Difficulty:** ⭐⭐⭐

## Problem summary

Implement a 3-bit LFSR given only as a schematic, targeting a DE1-SoC board: the three switches `SW` are the parallel-load data `R`, `KEY[1]` is the load control `L`, `KEY[0]` is the clock, and the three LEDs `LEDR` are the state `Q`. The circuit is three identical mux-plus-flip-flop cells — the same MUXDFF from [[Mt2015_muxdff]] — wired into a Galois feedback loop instead of a plain chain.

## Approach

Each cell in the schematic is `D = L ? R[i] : <feedback>`, and all three share `L`, so the mux factors out of the per-bit logic into a single `if`:

```verilog
if (KEY[1]) LEDR <= SW;         // L asserted: parallel load
else begin
    LEDR[0] <= LEDR[2];         // feedback bit into the bottom
    LEDR[1] <= LEDR[0];         // plain shift
    LEDR[2] <= LEDR[1] ^ LEDR[2];   // tapped bit
end
```

Reading the feedback structure off the schematic is the actual work. `Q[2]` is the output bit, and in Galois form it goes two places: back around to `Q[0]`, and into the XOR feeding `Q[2]` itself. Everything else shifts. The taps here correspond to x³+x²+1, which is primitive, so the seven non-zero states form one cycle:

`001 → 010 → 100 → 101 → 111 → 011 → 110 → 001`

Hand-stepping the first two transitions is the cheapest way to confirm you read the diagram correctly — and with 2³−1 = 7 states, walking the whole cycle takes under a minute and proves maximal length outright, which isn't practical for [[Lfsr5]]'s 31.

The problem explicitly allows submodules, and the schematic is literally three copies of one cell, so a structural solution that instantiates the [[Mt2015_muxdff]] module three times is equally valid and arguably closer to the drawing:

```verilog
// muxdff: the Mt2015_muxdff cell, renamed from top_module
muxdff u0 (.clk(KEY[0]), .L(KEY[1]), .r_in(SW[0]), .q_in(LEDR[2]),             .Q(LEDR[0]));
muxdff u1 (.clk(KEY[0]), .L(KEY[1]), .r_in(SW[1]), .q_in(LEDR[0]),             .Q(LEDR[1]));
muxdff u2 (.clk(KEY[0]), .L(KEY[1]), .r_in(SW[2]), .q_in(LEDR[1] ^ LEDR[2]),   .Q(LEDR[2]));
```

Two things that version forces you to get right, and which are worth noticing even if you don't write it: the cell has to be **renamed** from `top_module` (module names are one flat global namespace — see [[Module_fadd]]), and `LEDR` must *not* be `reg` there, since it's driven by submodule output ports rather than procedurally. Named connection over positional, as established in [[Module]].

The behavioural version above is kept as the solution because it's shorter and the feedback is visible in one place; the structural version's advantage is that the cell reuse — the point the exam question was making — is explicit.

## Gotchas / things to watch for

- **The bits shift *up* here, not down — don't pattern-match [[Lfsr5]]'s shape.** In [[Lfsr5]] every bit took its neighbour above (`q[n] <= q[n+1]`) with feedback into the top; here every bit takes its neighbour *below* (`Q[n] <= Q[n-1]`) with feedback wrapping into the bottom. Both are perfectly ordinary Galois LFSRs — direction is a drawing convention, not a rule — but writing the previous problem's structure from memory produces a working shift register with an entirely different (and non-maximal) sequence. Read the arrows in the schematic, every time.
- **Port names and schematic labels don't match, and nothing checks the mapping.** The diagram says `R`, `L`, `Q`, `Clock`; the module says `SW`, `KEY[1]`, `LEDR`, `KEY[0]`. Getting `KEY[1]` and `KEY[0]` backwards — using `KEY[1]` as the clock and `KEY[0]` as load — compiles cleanly and produces a circuit that does *something* on every button press. This is the same class of hazard as positional port connection in [[Module]]: identity carried by convention rather than by name. Transcribe the comment block from the problem into the port list (as the solution file does) so the mapping is checkable without going back to the wiki.
- **There is no reset — `L` is the only initialization, and loading `000` deliberately kills the circuit.** The all-zeros lock-up from [[Lfsr5]] is reachable *by the user* here, since `SW` is wired to physical switches: set them all low, press load, and the LEDs go dark forever until someone loads a non-zero value. That's a property of every LFSR with a data load and no zero-detection, not a bug in this design, but it's worth knowing before you demo it. Before the first load, all three flops are `x` and — because the feedback recirculates — they stay `x`, exactly as in [[Rotate100]].
- **`always @(posedge KEY[0])` clocks a register directly from a pushbutton, which passes the grader and is bad practice in real hardware.** Two separate problems. First, a mechanical switch *bounces*: one physical press produces tens to hundreds of edges over a few milliseconds, so the LFSR would advance an unpredictable number of states per press. Second, a raw I/O pin isn't on the FPGA's global clock network, so the "clock" arrives at the three flip-flops at different times — a clock-skew hazard, the same family of concern as the clock-gating warning in [[Countslow]]. The standard fix is the one this repo has already built: run everything on a real clock, bring the button in as ordinary *data*, synchronize it through two flops, and use an [[Edgedetect]]-style pulse as a clock **enable**. HDLBits's testbench drives `KEY[0]` as a clean clock, so none of this shows up in the grader — which is precisely why it's worth stating.
- **On a real DE1-SoC the `KEY` pushbuttons are active-low.** They read `1` at rest and `0` while pressed, so `posedge KEY[0]` is the *release* edge, and `if (KEY[1])` means "load while the L button is **not** pressed." The simulation doesn't care, so the code is correct as graded; the point is that "assume you're implementing this on the board" invites a hardware assumption that the code silently doesn't make. Board polarity belongs in a comment or a named inversion at the top of the module, not in the reader's head.
- **Three separate slice assignments must partition `LEDR` exactly** — same structural risk as [[Lfsr5]]. Here they do (`[0]`, `[1]`, `[2]`), but a missing line would leave that bit holding its own value forever rather than raising any error. The concatenation form `LEDR <= {LEDR[1] ^ LEDR[2], LEDR[0], LEDR[2]};` restores the width check at a glance — note the reversal, since concatenation lists MSB first while the per-bit form reads bottom-up.
- **Non-blocking assignment is again doing real work.** `LEDR[1] <= LEDR[0]` and `LEDR[0] <= LEDR[2]` both read the pre-edge state; with blocking `=`, `LEDR[0]` would already have been overwritten by the time line two runs, and the shift would collapse. See [[Lfsr5]] for the same point in more detail.
- **`LEDR` is declared `output [2:0]` with no `reg`** but is assigned procedurally — HDLBits's own header again, legal only because the grader compiles as SystemVerilog. `output reg [2:0] LEDR` is the portable form and still passes; see [[Dff8ar]].

## Solution

See `mt2015_lfsr.v`.
