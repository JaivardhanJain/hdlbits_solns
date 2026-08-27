# Module_shift

**HDLBits link:** https://hdlbits.01xz.net/wiki/Module_shift
**Category:** Verilog Language: Modules: Hierarchy
**Difficulty:** ⭐⭐

## Problem summary

Given a D flip-flop module `my_dff ( input clk, input d, output q )`, instantiate three of them and chain them into a length-3 shift register. `clk` goes to all three; `q` comes out three clock cycles behind `d`.

## Approach

This is the first problem in the chapter where instantiation stops being transcription and starts being *design*. The previous three had one instance and a fixed mapping. Here the structure is ours to build, and the shape of it is the answer:

```
d --> [d1] --a--> [d2] --b--> [d3] --> q
      ^           ^           ^
      +-----------+-----------+
                 clk
```

Two signal classes behave completely differently. `clk` **fans out** — the same net attaches to all three instances, unchanged. The data path **threads** — each stage's `q` becomes the next stage's `d`. Getting a chain right is mostly a matter of keeping those two ideas separate in your head while writing three near-identical lines.

The internal links need nets of their own, since a wire is only implied where a port already exists. `d` and `q` are ports and already exist; the two joints between the stages are not, so `wire a, b;` declares them. In general a chain of *N* stages needs *N−1* internal wires.

`top_module`'s three instances are connected by position, matching how the problem presents `my_dff`. `alt1` in the solution file is the same circuit written with named connection — the style Module_name (22) argued for, and the one to reach for by default. With three stages the positional form is still readable; by the time a chain has a clock, a reset, an enable and a load, it isn't.

## Gotchas / things I got wrong initially

- **Naming the internal wire after the stage that *consumes* it, rather than the one that drives it.** Both conventions get used, and neither is wrong, but mixing them mid-chain is how stages get cross-wired. Pick one and hold it — here `a` is "output of d1", `b` is "output of d2", consistently.

- **A typo'd wire name doesn't error, it silently forks the chain.** Write `my_dff d2 ( clk, ab, b );` and Verilog happily invents a fresh 1-bit implicit net called `ab`: `a` now drives nothing, `d2`'s input floats `x`, and the register is broken from stage 2 onward with no diagnostic at all. This is the same implicit-net hazard from Wire_decl and Gatesv, and chained instantiations are where it bites hardest because the names are short and near-identical by design. `` `default_nettype none `` at the top of the file turns this exact bug into a compile error, which is why it's standard in production code.

- **Driving one wire from two instances is the other half of that mistake.** `my_dff d2 ( clk, b, a );` — inputs and outputs transposed — leaves `a` with two drivers and `b` with none. Simulators resolve a multiply-driven `wire` to `x` on conflict rather than refusing to elaborate, so again the first symptom is a bad waveform, not an error message. Reading the chain out loud ("d1 drives a, d2 reads a and drives b") catches both variants faster than staring at the code.

- **Instance names must be unique, and so must wire names.** The problem page calls this out explicitly because copy-pasting the line three times and only editing the signals is the natural way to write it — and leaves you with three instances all called `d1`. That one *is* a compile error, unlike most of the above.

- **`q` doesn't need to be `reg`.** It's an output port driven directly by `d3`'s output port — a structural connection, not a procedural assignment — so it stays an implicit `wire`. The `output reg` convention this repo follows (from Dff onward) applies to outputs assigned inside an `always` block; ports fed by a sub-module instance are the opposite case, and declaring `output reg q` here would actually be illegal.

- **There's no reset, so the first three cycles of `q` are `x`.** Flip-flops power up unknown — the theme running from Exams_m2014_q4d and Count15 — and nothing clears them here, so `q` is `x` until real data has shifted all the way through. That's correct behaviour for this problem, not a bug, but it's worth recognising in a waveform rather than hunting for a wiring error. A real design would either reset the chain or tolerate the startup window deliberately.

- **Order of the three statements in the file is irrelevant.** Writing `d3` first still builds the same circuit — instantiations describe structure that all exists simultaneously, not steps that execute. Keeping them in dataflow order is purely for the reader, but it's worth doing for exactly that reason.

## Solution

See `module_shift.v`
