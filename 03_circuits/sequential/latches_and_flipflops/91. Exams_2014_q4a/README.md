# Exams_2014_q4a

**HDLBits link:** https://hdlbits.01xz.net/wiki/exams/2014_q4a
**Category:** Circuits: Sequential (Latches and Flip-flops)
**Difficulty:** ⭐⭐⭐

## Problem summary

Implement one stage of an *n*-bit shift register that supports both **parallel load** and **shift-with-enable**. Each stage has two select lines: `L` (load) and `E` (enable). `w` is the bit shifting in from the previous stage, `R` is the parallel-load data for this bit, and `Q` is both the stage's output and the value fed to the *next* stage's `w`.

## Approach

Two muxes in series, then a flop — one level deeper than [[Mt2015_muxdff]]:

- **Enable mux** (`t`): when shifting is enabled (`E=1`), take the incoming bit `w`; otherwise hold by feeding `Q` back into itself.
- **Load mux** (`d`): when loading (`L=1`), override everything with the parallel data `R`; otherwise pass through whatever the enable mux decided.

```verilog
t = E ? w : Q;   // shift-enable stage
d = L ? R : t;   // load stage — L wins
```

`L` sitting on the outer mux is not arbitrary — it encodes the priority the spec wants: **load beats shift.** If both `L` and `E` were asserted in the same cycle, this stage loads `R`, it does not shift in `w`. Swap the nesting (`E` on the outside, `L` on the inside) and you get the opposite priority — a different, wrong circuit that happens to agree with the correct one on every input except `L=E=1`.

As in Mt2015_muxdff, the two-block form (combinational mux logic feeding a clocked register) mirrors the schematic directly; `alt1.v` collapses it into one block with nested ternaries, `Q <= L ? R : (E ? w : Q);`, which reads the priority right off the expression — outermost condition wins.

Chain `n` of these together — `w[i] = Q[i-1]`, common `R[i]`, common `L`/`E` — and the result is a parallel-load shift register, the structure this cell is one slice of.

## Gotchas / things to watch for

- **Mux nesting order encodes priority — get it backwards and the bug only shows up when both selects are asserted together.** This is the load-vs-shift version of the priority-encoder lesson HDLBits builds up in the Procedures chapter (`always_case2`, `always_casez`): when two conditions can both be true, whichever one is checked "outermost" (last in an if/else-if chain, or outermost in nested ternaries) wins, and that has to match the spec's intent, not just feel natural. Test vectors that only ever set one select line at a time will pass either ordering — the priority case is exactly the one worth adding to a testbench deliberately.
- **`t` and `d` both need to be `reg`, and `Q` needs `reg` too.** Three procedurally-assigned signals in this file, three easy places to accidentally leave a `wire` declaration in from a template. Same rule as [[Mt2015_muxdff]]: `assign`/module-output → `wire`, `always` → `reg`/`logic`.
- **Reading `Q` inside the combinational block that also feeds `Q`'s own register is fine, and is a different situation from [[Exams_m2014_q4d]]'s feedback.** There, `out` fed back through the *same* clocked always block; here, `Q` is read combinationally to build `t`, then the result is registered separately. Both are legitimate, but they're not the same pattern — this one is a mux selecting "new value vs. current value," not a state-update recurrence.
- **This is a building-block problem — the grader only ever instantiates one stage.** It's tempting to reach for a `parameter`-ized width or to wire up `w`/`R` as vectors, but the module declaration is fixed at one bit per the spec (`input w, R, E, L`), and the *chaining* into an n-bit register happens outside this module, in whatever instantiates it. Solve exactly the interface given, not the larger structure it implies — the same discipline as [[Fadd]] before it gets chained into [[Adder3]].

## Solution

See `exams_2014_q4a.v` (two-block form) and `alt1.v` (single-block nested-ternary form).
