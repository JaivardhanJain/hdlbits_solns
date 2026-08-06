# Exams_m2014_q4a

**HDLBits link:** https://hdlbits.01xz.net/wiki/exams/m2014_q4a
**Category:** Circuits: Sequential (Latches and Flip-flops)
**Difficulty:** ⭐⭐

## Problem summary

Build a **D latch** from the given schematic: while `ena` is high the output follows `d` continuously, and when `ena` goes low the output freezes at whatever `d` was at that moment.

## Approach

A latch is level-sensitive, not edge-sensitive, so the sensitivity list is `always @(*)` — the block re-evaluates whenever any input changes, not on a clock edge. Inside it, a single guarded assignment:

```verilog
if (ena) q <= d;
```

There is deliberately **no `else`**. That incomplete `if` is the entire mechanism: on any path where `q` isn't assigned, `q` must keep its old value, and the only hardware that can do that is a storage element. The synthesizer looks at a combinational block that fails to fully specify its output and infers a latch to cover the gap.

This is worth sitting with, because it is the exact construct every previous problem in this chapter has treated as a hazard. Here it's the deliverable. Quartus will emit an "inferred latch" warning on this design, and the HDLBits problem page says so explicitly — the warning is correct, and this time it's telling you the thing you wanted happened.

### Transparent vs. opaque

The two states are worth naming, since the vocabulary shows up constantly in timing discussions:

| `ena` | Behaviour | Name |
|:---:|---|---|
| 1 | `q` tracks `d` continuously, like a wire | **transparent** |
| 0 | `q` holds the last value `d` had | **opaque** / latched |

A latch is "transparent" in the literal sense: while enabled, changes on `d` pass straight through to `q` with only gate delay. That's the fundamental difference from a flip-flop, which samples `d` at one instant and ignores it the rest of the time.

## Gotchas / things to watch for

- **`always @(*)`, not `always @(posedge ena)`.** After five straight flip-flop problems, `posedge` is reflex — and `always @(posedge ena)` even simulates plausibly, capturing `d` on the enable's rising edge. But that's a flip-flop clocked by `ena`, not a latch: it would sample `d` once at the moment `ena` rises and then ignore `d` for the whole time `ena` is high, instead of staying transparent. A latch must react to the *level*, which means every input change has to re-trigger the block.
- **Omitting the `else` is the design, not an oversight.** Someone reviewing this file who's internalized "always assign in every branch of a combinational block" will want to add `else q <= q;` — and here that changes nothing functionally (it's still a latch either way), but it obscures the intent. More importantly, don't let this problem overwrite the general rule: an unintentional incomplete `if` in a combinational block is still one of the most common real bugs in RTL, because a latch where you expected pure logic breaks static timing analysis and creates data-dependent glitch paths. The rule from [[Dff16e]] holds in both directions — in a *clocked* block a missing branch means "hold" and is fine; in a *combinational* block it means "latch," and is fine only when a latch is what you're building.
- **Add a comment saying the latch is intentional.** This is the practical, industry-relevant habit: since the toolchain warning for a deliberate latch is identical to the warning for an accidental one, teams that don't annotate deliberate latches end up training themselves to ignore latch warnings entirely — at which point the real ones sail through. Most style guides ask for an explicit comment, and many CI lint setups require a waiver pragma on the line.
- **HDLBits asks for `<=` here, which is a genuine edge case.** The usual guideline — blocking `=` in combinational blocks, non-blocking `<=` in sequential ones — doesn't cleanly classify a latch: it lives in a combinational-style block but *is* a sequential element. HDLBits's own hint resolves it in favour of `<=` on the grounds that it's a storage element, and that's what this solution uses. Either assignment works for a single-statement block like this one; the reasoning only starts to matter in blocks with several dependent statements, where the [[Dff]] race-condition argument applies.
- **A latch is not a cheaper flip-flop.** Latches use fewer transistors in custom ASIC design and show up in high-performance pipelines deliberately, but on an FPGA they're generally worse: most fabrics implement a latch *out of* a flip-flop plus extra logic, so it costs more, not less, and it complicates timing closure. If you find yourself inferring one on an FPGA without meaning to, the fix is almost always to complete the `if`, not to keep the latch.
- **`q` needs to be `reg`.** Procedurally assigned, same rule as [[Dff8ar]] — HDLBits's bare `output q` only passes because their grader compiles as SystemVerilog.

## Solution

See `exams_m2014_q4a.v`.
