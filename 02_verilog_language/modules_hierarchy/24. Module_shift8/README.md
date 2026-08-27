# Module_shift8

**HDLBits link:** https://hdlbits.01xz.net/wiki/Module_shift8
**Category:** Verilog Language: Modules: Hierarchy
**Difficulty:** ⭐⭐⭐

## Problem summary

[Module_shift](../23.%20Module_shift/README.md) widened to 8 bits, plus a mux. Chain three `my_dff8` stages into an 8-bit-wide shift register of depth 3, then use `sel[1:0]` to output the data delayed by 0, 1, 2, or 3 cycles.

## Approach

The register half is Module_shift with `wire` replaced by `wire [7:0]` — the chain structure is unchanged, only the width. That's the point the problem is making: connecting a vector port to a vector net works exactly like connecting a scalar, provided the widths agree.

The new work is the mux, which taps the chain at four points:

```
        +--- sel=0
        |         +--- sel=1     +--- sel=2     +--- sel=3
        |         |              |              |
   d ---+--> [d1] --o1--> [d2] --o2--> [d3] --o3
                                                    --> 4:1 mux --> q
```

The undelayed tap is `d` itself, which is easy to miss when counting: four selections, but only three flip-flop stages. `sel` counts *cycles of delay*, and zero delay means bypassing the register entirely.

Built as a combinational `always @(*)` block with a `case`, which is the shape HDLBits suggests and the same one used back in Mux9to1v. Because `q` is assigned procedurally, it has to be declared `output reg [7:0] q` — HDLBits's given declaration omits the `reg`, which compiles there only because the grader runs in SystemVerilog mode. This repo's convention (established at Dff) is to add it, so the code is legal Verilog-2001. Note the contrast with Module_shift, where `q` was driven straight from a sub-module port and `reg` would have been *wrong*: what matters is whether the signal is assigned inside a procedural block, not whether the circuit contains flip-flops.

`alt1` in the solution file shows the same circuit with named port connections and the taps collected into an array indexed directly by `sel`. It scales to a deeper register without growing new case arms, at the cost of being less obvious to a reader who hasn't seen the idiom.

## Gotchas / things I got wrong initially

- **Forgetting that `sel == 0` is the undelayed input.** Three flip-flops, four choices. Wiring `sel` to `o1/o2/o3` plus something else, or off-by-one-ing the whole table so `sel=3` reads `o2`, gives a circuit that passes casual inspection and fails the delay check. Reading `sel` as "how many cycles of delay" rather than "which flip-flop" makes the mapping fall out correctly.

- **An incomplete `case` in a combinational block infers a latch.** Here all four values of a 2-bit `sel` are listed, so `q` is assigned on every path and the block is genuinely combinational. Drop one arm — or widen `sel` later without revisiting this block — and the synthesiser must hold the old value for the unlisted case, which means a latch. Adding `default:` is the habit that makes this impossible to get wrong; the always_if2 / always_nolatches problems later in the chapter are about exactly this failure.

- **`always @(*)`, not a hand-written sensitivity list.** `always @(sel)` would compile and simulate wrong: change `d` while `sel` holds at 0 and the block never re-evaluates, so `q` goes stale. `@(*)` derives the list automatically from everything read inside. Hand-maintained sensitivity lists are a classic source of simulation-synthesis mismatch, where the synthesised hardware behaves correctly and only the simulation is broken.

- **Blocking `=` inside the mux is correct, and non-blocking would be the error.** This is a combinational block, so `=` is right — the same rule as everywhere since Dff, just in the direction people forget. The flip-flops in this design live inside `my_dff8`; nothing in `top_module` is clocked, despite `clk` being a port.

- **Width mismatches on port connections are silent.** The problem page raises this deliberately: attaching a net of the wrong width to a vector port zero-pads or truncates without complaint. This exercise keeps everything at 8 bits so nothing goes wrong, but that's the setup, not a guarantee — declaring `wire [6:0] o2;` by typo would quietly drop the top bit of the chain. Same family as the sized-literal lesson from Step One: Verilog's willingness to resize is a convenience that doubles as a bug factory.

- **The three internal buses must be declared, and must be `wire`.** Each is driven by a sub-module output port, i.e. structurally, so `reg` would be illegal — and unlike scalars, an undeclared vector can't be saved by implicit net creation, since implicit nets are always 1 bit wide. That produces a genuine width mismatch rather than the silent fork Module_shift warned about.

- **`2'h0`–`2'h3` versus `2'd0`–`2'd3`.** Both are fine and both are correctly sized. Hex for a two-bit value reads slightly oddly, but the property that matters — the literal is explicitly sized to match `sel` — holds either way. An unsized `case (sel) 0: ... 1: ...` also works here, but sized case labels are the safer habit once the selector is wider than a few bits.

## Solution

See `module_shift8.v`
