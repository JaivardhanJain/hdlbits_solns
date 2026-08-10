# Countslow

**HDLBits link:** https://hdlbits.01xz.net/wiki/countslow
**Category:** Circuits: Sequential (Counters)
**Difficulty:** ⭐⭐⭐

## Problem summary

The same 0–9 decade counter as [Count10](../99.%20Count10/README.md), plus a `slowena` input: the counter only advances on a clock edge where `slowena` is high. On any edge where it's low, `q` just holds. Synchronous `reset` still forces `q` to 0 regardless of `slowena`.

## Approach

```verilog
always @ (posedge clk) begin
    if (reset)         q <= 4'd0;
    else if (slowena) begin
        if (q == 4'd9) q <= 4'd0;
        else           q <= q + 4'd1;
    end
    // slowena == 0: no assignment, q holds its value
end
```

This nests the whole Count10 body inside an `else if (slowena)` branch. The key idea — and the reason this problem is rated above the plain counters — is what happens when *neither* `reset` nor `slowena` is true: **the `always` block runs on every clock edge regardless, but this time it's allowed to fall through without assigning `q` at all.** That's legal and correct in a clocked block, and it's exactly how you build a "hold" state: the previous non-blocking assignment already latched a value into the register, and skipping the assignment this cycle just means the flip-flop keeps what it had. This is a different situation from a *combinational* `always @(*)` block skipping an assignment, which infers an unwanted latch — see [Always_if2](../../../../02_verilog_language/) — because there the "memory" a skipped branch creates is an accident. Inside a clocked block, "don't assign, so it holds" is the intended, idiomatic way to build an enable.

`slowena` here is doing exactly what a hardware enable is supposed to do: gating whether the register's D input changes, not gating the clock itself. That distinction is the real content of this problem.

## Gotchas / things to watch for

- **Gating the clock instead of gating the data — the industry mistake this problem exists to head off.** A tempting shortcut is something like `assign gated_clk = clk & slowena;` and clocking the register off `gated_clk` instead of `clk`. It's intuitively "correct" (the register genuinely only ticks when enabled) and it's precisely the technique real chips avoid, for reasons that don't show up in a simulator: `slowena` is combinational logic, and combinational logic glitches. If `slowena` bounces briefly while `clk` is high, `gated_clk` gets a spurious extra edge the register sees as a real clock pulse — a bug that's invisible in RTL simulation (where signals settle instantly) and only shows up on real silicon, often intermittently, sometimes only under specific temperature or voltage corners. Production designs that do need clock gating use dedicated integrated clock-gating cells with built-in glitch filtering, not a raw AND gate — and it's a technique reserved for power optimization on macro blocks, applied by tools/methodology, not something to reach for casually in RTL. The correct RTL pattern is what's used here: keep `always @(posedge clk)` ungated, and make `slowena` gate the *data path* by conditionally skipping the assignment.

- **The dead `q_slow` register in the version this was drafted from.** An earlier draft declared `reg [3:0] q_slow;`, assigned it `0` alongside `q` on reset, and then never touched it again — no read, no other write. It cost nothing functionally (HDLBits doesn't check for unused signals), but it's a real code-smell in any serious codebase: an unused register is either a sign of an incomplete circuit (a common bug where you meant to use it and forgot) or leftover cruft from an earlier draft that a linter (or `-Wall` in Icarus Verilog) will flag. Left in, it forces every future reader to go looking for where `q_slow` matters before concluding it doesn't. It's removed in this version — if you don't use a signal, don't declare it.

- **Priority order: `reset` must stay the first, unconditional check.** As in every earlier counter in this chapter, `reset` needs to override `slowena`, not compete with it — a design where reset is nested *inside* the `slowena` branch (`if (slowena) begin if (reset) ... end`) would silently stop resetting whenever `slowena` happens to be low, which is a real requirements bug, not a style nit: the spec says reset always wins.

- **Testing `slowena` in the sensitivity list, or worse, as a second `posedge` trigger.** `slowena` is a level — an enable — not an edge source. It belongs in the `if`/`else if` chain inside the block, exactly where `reset` sits in every prior problem, not in `always @(posedge clk or posedge slowena)`. Only `clk` should ever appear in this design's sensitivity list; anything else there changes what event makes the block re-evaluate, and re-evaluating on a `slowena` edge instead of only on `clk` edges is a different (and wrong) circuit.

- **`if (q == 9) q <= 0; else q <= q + 1;` written *outside* the `slowena` check.** It's easy to structure this as `if (reset) ...; if (q==9) q <= slowena ? 0 : q; else q <= slowena ? q+1 : q;` or similar — functionally salvageable, but it obscures the actual structure of the circuit (an enable gating an otherwise-ordinary decade counter) behind a maze of ternaries. Nesting `slowena` as its own `else if` branch, with the terminal-count logic entirely inside it, keeps the three concerns — reset, enable, count — visibly separate, which is the same instinct as keeping `<=` consistent per-branch that was established back in [Dff8r](../../latches_and_flipflops/82.%20Dff8r/README.md).

- **`output [3:0] q` without `reg`** — same standing note as every counter this chapter: HDLBits's SystemVerilog frontend accepts it, strict Verilog-2001 doesn't. `output reg [3:0] q`.

## Solution

See `countslow.v`
