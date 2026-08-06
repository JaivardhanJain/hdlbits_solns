# Exams_m2014_q4d

**HDLBits link:** https://hdlbits.01xz.net/wiki/exams/m2014_q4d
**Category:** Circuits: Sequential (Latches and Flip-flops)
**Difficulty:** ⭐⭐

## Problem summary

Implement the given schematic: a D flip-flop whose input is the XOR of `in` and the flop's own output. There is no reset of any kind.

## Approach

The output feeds back into the logic driving its own input, so the whole circuit is one line:

```verilog
always @(posedge clk)
    out <= in ^ out;
```

This is the first circuit in the chapter with **feedback** — `out` appears on both sides of the assignment. That's not circular reasoning, because the flop breaks the loop in time: the `out` on the right-hand side is the value from *before* this clock edge, and the assignment produces the value for *after* it. There's no combinational path from `out` back to itself, just a path through the flop, which is exactly what makes the circuit legal and stable.

Functionally it's a **T flip-flop**: XOR with 1 inverts, XOR with 0 leaves alone, so `in=1` toggles `out` on that edge and `in=0` holds it. Seen over time, `out` is the running parity of every `1` that has appeared on `in`.

| `in` | Effect on `out` |
|:---:|---|
| 0 | hold |
| 1 | toggle |

### Why no `initial` block — and what actually happens without one

Two separate questions here, and they have different answers.

**In simulation, `out` starts as `x`** (unknown). Verilog initializes every `reg` to `x`, and XOR propagates unknowns: `x ^ 0` is `x`, `x ^ 1` is `x`. So the first clock edge computes `in ^ x` = `x` and writes `x` back into `out`. Every subsequent edge does the same. With no reset port in the interface, nothing ever injects a known value, so **`out` stays `x` for the entire simulation** — the waveform is a flat red line, not a toggling signal.

That sounds broken, but it's the correct model of the circuit as specified: a real flip-flop with no reset genuinely does have an undefined power-up state, and `x` is Verilog's way of saying "the hardware doesn't determine this." HDLBits's reference implementation has the identical property, so the grader's DUT-vs-reference comparison agrees at every timestep and the solution passes.

**On real hardware it doesn't stay unknown.** FPGA flip-flops power up to a defined state from the configuration bitstream — 0 unless told otherwise — so on an actual Altera or Xilinx part this circuit starts at 0 and behaves as the clean toggle/parity circuit described above. ASIC flops have no such guarantee and really can come up either way, which is why ASIC designs reset essentially everything.

**So why not just add `initial out = 0;`?** Because it's the wrong tool at three levels:

1. **It isn't what the problem specifies.** The schematic shows no reset. Adding initialization models a circuit the question didn't ask for, and here it risks *disagreeing* with the grader's reference model rather than matching it.
2. **It's not portable synthesis.** FPGA tools do honour `initial` for register power-up values, but ASIC synthesis ignores it outright. Code that depends on `initial` for correctness works on one target and silently breaks on the other.
3. **Reset is the real answer.** If a design needs a defined starting state, that's what a reset port is for — [[Dff8r]] and [[Dff8ar]] are the two ways to write it. `initial` belongs in testbenches; in RTL it's at best an FPGA-specific optimization, never the mechanism you rely on.

## Gotchas / things to watch for

- **Reading and writing the same register in one clocked block is fine — and it's why `<=` matters.** `out <= in ^ out;` works because non-blocking assignment evaluates the entire right-hand side using pre-edge values, then updates. That's the [[Dff]] rule doing real work for the first time: with a blocking `out = in ^ out;` this single statement still happens to behave the same, but the moment a second block reads `out` on the same edge, blocking assignment lets it see the new value early and the design becomes order-dependent. Feedback circuits are exactly where the non-blocking habit stops being a formality.
- **An all-`x` waveform here is expected, not a bug.** The instinct on seeing `out` stuck at `x` is to go hunting for a coding error. There isn't one — it's the honest consequence of an unreset flop. Recognizing the difference between "`x` because my code is wrong" and "`x` because the hardware genuinely has no defined value yet" is a real debugging skill, and it's also why `x` propagation is worth understanding rather than suppressing.
- **Don't add ports the interface doesn't have.** The temptation to "fix" the unknown state by adding a `reset` input breaks the grader immediately — HDLBits matches ports by name against a fixed declaration. More generally, when a schematic omits reset, that omission is part of the spec.
- **`in ^ out`, not `in ^ in` or a chain of ANDs.** The XOR-with-self-feedback pattern is the standard T flip-flop construction and shows up constantly later — in counters, in LFSRs ([[Lfsr5]] and friends), and in parity checkers. Worth recognizing on sight rather than re-deriving.
- **`out` must be `reg`.** Procedurally assigned; HDLBits's bare `output out` only compiles because their grader treats the file as SystemVerilog. Same note as [[Dff8ar]].

## Solution

See `exams_m2014_q4d.v`.
