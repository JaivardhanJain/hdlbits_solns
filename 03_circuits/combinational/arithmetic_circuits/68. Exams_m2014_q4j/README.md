# Exams/m2014_q4j (Adder)

**HDLBits link:** https://hdlbits.01xz.net/wiki/Exams/m2014_q4j
**Category:** Circuits: Combinational (Arithmetic)
**Difficulty:** ⭐⭐

## Problem summary

The problem gives a schematic of four full adders chained together (labelled "FA") and asks you to implement it: two 4-bit numbers `x`, `y` go in, and a 5-bit `sum` comes out — the extra bit is there to hold the final carry-out of the last adder stage.

## Approach

This is Adder3's structure, widened by one bit and with a twist on the output: instead of exposing every intermediate carry as a separate `cout` port, the final carry from the last full adder is wired directly into the top bit of `sum` (`sum[4]`), since that's the only carry the module's I/O actually asks for.

```
fa1: x[0], y[0], 1'b0 -> t1, sum[0]
fa2: x[1], y[1], t1   -> t2, sum[1]
fa3: x[2], y[2], t2   -> t3, sum[2]
fa4: x[3], y[3], t3   -> sum[4], sum[3]   <- fa4's cout lands in sum[4], not a separate port
```

The commented-out line, `assign sum = x + y;`, is a completely different way of describing the same circuit — and this problem is a good place to actually name that difference, since both are given side by side.

### Structural vs. behavioural modelling

**Structural modelling** describes a circuit as an interconnection of sub-modules or primitives — you say *how* the circuit is built, instance by instance and wire by wire, the same way you'd read it off a schematic. `top_module` here is structural: it says nothing about addition directly, it just wires four `fa` instances together in the exact shape of the given diagram.

**Behavioural modelling** describes a circuit by *what it computes*, using higher-level constructs (`+`, `always` blocks, `?:`, `case`, etc.) and lets the synthesis tool figure out the gate-level implementation. `assign sum = x + y;` is behavioural: it says "sum is x plus y" and doesn't commit to any particular adder architecture — the synthesizer is free to implement it as a ripple-carry chain, a carry-lookahead adder, or whatever else fits its area/timing targets best.

Both compile to a working 4-bit adder here, but they exist for different reasons. Structural modelling gives you exact control over what hardware gets built — essential when you're matching a given schematic (like this problem), instantiating vendor-hardened primitives (block RAMs, DSP slices, hard adder carry chains on an FPGA), or building up a hierarchy from smaller verified blocks. Behavioural modelling is shorter, easier to get right, and lets the synthesis tool apply optimizations you'd have to hand-derive yourself — which is why, in industry RTL, most functional datapath logic (adders, comparators, muxes) is written behaviourally by default, and structural instantiation is reserved for cases where you specifically need to control the netlist.

## Gotchas / things I got wrong initially

- **Treating structural as inherently "more correct" or "more professional."** It's tempting to think hand-instantiating full adders is the more rigorous approach because it's more explicit. In practice the opposite is usually true for ordinary datapath logic: `assign sum = x + y;` is shorter, has no wiring to get wrong, and lets the synthesis tool pick a faster adder architecture than a naive ripple-carry chain if timing requires it. Reach for structural modelling when you have a specific reason to control the exact gates (matching a spec diagram, targeting a hardened primitive), not as a default style choice.
- **Wiring the final carry into the wrong bit.** `fa4`'s ports are `(x, y, cin, cout, sum)`, and the instantiation connects `cout` to `sum[4]` and `sum` to `sum[3]` — get that pair backwards (`sum[3]`, `sum[4]` swapped) and the circuit still compiles, still looks structurally right at a glance, and only produces the wrong answer on inputs that generate a final carry. This is the same positional-instantiation risk flagged in Adder3, just easier to miss here because `sum[3]` and `sum[4]` look similar enough to typo.
- **Assuming `assign sum = x + y;` and the structural version are obviously equivalent.** They are here, but only because `sum` is declared as the full 5-bit width the addition needs — Verilog correctly zero-extends `x` and `y` (both unsigned 4-bit) and keeps all 5 result bits since the left-hand side is 5 bits wide. If `sum` were declared 4 bits instead, this exact same line would silently truncate away the carry bit, the same width-truncation trap called out back in Hadd and Fadd. Don't assume "behavioural version = shorter = safer" without checking the target width still fits what the operation actually produces.
- **Not actually verifying the two versions against each other.** Since both `top_module` and `alt1.v` are meant to compute the same thing, the useful check isn't "does this look right," it's simulating both over all 256 input combinations (`x`, `y` each 4 bits) and diffing the `sum` outputs. That's cheap to do here and is exactly the kind of check that would have caught the `cout`/`sum` swap above — eyeballing wiring against a diagram is not a substitute for actually running it.

## Solution

See `exams_m2014_q4j.v` for the structural form (matching the given diagram), and `alt1.v` for the behavioural (`+`) form.
