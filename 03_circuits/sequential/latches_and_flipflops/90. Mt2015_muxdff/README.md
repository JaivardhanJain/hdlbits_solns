# Mt2015_muxdff

**HDLBits link:** https://hdlbits.01xz.net/wiki/mt2015_muxdff
**Category:** Circuits: Sequential (Latches and Flip-flops)
**Difficulty:** ⭐⭐⭐

## Problem summary

Implement the given schematic: a 2-to-1 multiplexer feeding a D flip-flop. `L` selects which value gets captured on the clock edge — `r_in` when `L` is 1, `q_in` when `L` is 0.

## Approach

The names are the giveaway that this is one bit sliced out of a larger machine: `L` is *load*, `r_in` is the value being loaded in parallel, and `q_in` is the neighbouring bit arriving from the shift path. Replicate this slice N times, chain each `q_in` to the previous stage's `Q`, and you have a **loadable shift register** — the standard "load then shift" primitive that shows up throughout the shift-register and FSM chapters. Worth recognizing now, because HDLBits reuses this exact cell later.

The circuit is written as two blocks that mirror the schematic one-for-one:

- a **combinational** block for the mux, producing the intermediate signal `d`
- a **sequential** block for the flop, registering `d` into `Q`

That split is a real design idiom, not just verbosity — it's the same "combinational next-state logic + clocked state register" structure used for FSMs, and keeping the two in separate blocks is what makes larger designs readable. `alt1.v` shows the collapsed alternative, `Q <= L ? r_in : q_in;`, which is what most engineers would actually write for something this small. Both synthesize identically.

Note how the assignment operators differ between the two blocks, and that this is deliberate: **blocking `=` in the combinational block, non-blocking `<=` in the clocked one.** This problem is the first in the chapter where both kinds of block appear together, so it's the first place the rule has two sides to get right rather than one.

## Gotchas / things to watch for

- **`d` must be declared `reg`, not `wire`.** This is a hard compile error, not a style point: `wire` is a net type and nets can only be driven by continuous assignment (`assign`) or a module output. The moment a signal is assigned inside an `always` block it has to be a variable — `reg` in Verilog-2001, or `logic` in SystemVerilog. The declaration and the assignment style must agree, and the mismatch is easy to introduce because "it's just an internal wire" is how you *think* about `d` when reading the schematic. Rule of thumb: `assign` → `wire`; `always` → `reg`.
- **Use `default` rather than enumerating `1'b1` in the case.** Listing `1'b0` and `1'b1` looks exhaustive for a one-bit selector, and for synthesis it is — the tool sees both values covered and builds a mux with no latch. But in *simulation* a four-state signal can also be `x` or `z`, and if `L` is unknown neither branch matches, so `d` keeps its previous value: a latch in the simulation model that the synthesized hardware doesn't have, and a source of sim/synthesis mismatch that's genuinely painful to debug. Writing the last branch as `default` closes the gap for free. This is the general form of the incomplete-`if` problem from [[Exams_m2014_q4a]] — a `case` can leave gaps just as easily as an `if`, it just hides them better.
- **Two blocks means two assignment conventions, and mixing them up is the classic error.** Writing `d <= q_in;` in the combinational block is the tempting slip, since `<=` has been the right answer for the last ten problems. In a combinational block, non-blocking assignment schedules the update for the end of the timestep, so any statement later in the same block reads the *stale* value of `d` — harmless in a one-statement block, but wrong as soon as the logic has multiple dependent steps, and it desynchronizes simulation from the hardware. The convention exists precisely so the two block types can't interfere: `always @(*)` → `=`, `always @(posedge clk)` → `<=`.
- **`Q` must be `reg` too.** Already correct here, but it's the same rule as `d` — see [[Dff8ar]] for why HDLBits's bare `output Q` gets away with it.
- **Don't overthink which input goes with which select value.** `L=1` loads `r_in`, `L=0` passes `q_in`. Swapping them produces a circuit that shifts when it should load and vice versa — it still compiles, still looks structurally right, and only fails on the specific test vectors that exercise `L`. When a mux's inputs are named rather than numbered, re-read the schematic before assuming the ordering.

## Solution

See `mt2015_muxdff.v` (two-block form, mirroring the schematic) and `alt1.v` (single-block ternary form).
