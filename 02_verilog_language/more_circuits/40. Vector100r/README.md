# Vector100r

**HDLBits link:** https://hdlbits.01xz.net/wiki/Vector100r
**Category:** Verilog Language: More Verilog Features
**Difficulty:** ⭐⭐⭐

## Problem summary

Reverse the bit order of a 100-bit input: `out[99]` gets `in[0]`, `out[98]` gets `in[1]`, and so on down to `out[0]` getting `in[99]`.

## Approach 1 — procedural `for` loop (`vector100r.v`)

[Vectorr](../../vectors/17.%20Vectorr/README.md) reversed 8 bits by writing out the concatenation `{in[0], in[1], ..., in[7]}`. At 100 bits that's not practical, so this uses a loop:

```verilog
always_comb begin
    for (int i = 0; i < 100; i++) begin
        out[99 - i] = in[i];
    end
end
```

### The loop syntax

`for (init; condition; step) statement` works the same way as in C:

- **`int i = 0`** declares the loop variable and sets its starting value. Declaring it inside the `for` is SystemVerilog; it only exists inside the loop.
- **`i < 100`** is checked before each iteration. The loop stops once it's false, so `i` runs 0 to 99, exactly 100 iterations.
- **`i++`** runs after each iteration. Also SystemVerilog; Verilog-2001 has no `++`.
- **`begin` / `end`** wrap the body. With only one statement here they're optional, but they make adding a second statement safe.

The Verilog-2001 version of the same loop declares the variable outside and spells out the increment:

```verilog
integer i;
always @(*) begin
    for (i = 0; i < 100; i = i + 1)
        out[99 - i] = in[i];
end
```

### What the loop turns into

Synthesis unrolls the loop at compile time into 100 separate assignments:

| `i` | statement |
|---|---|
| 0 | `out[99] = in[0];` |
| 1 | `out[98] = in[1];` |
| 2 | `out[97] = in[2];` |
| … | … |
| 99 | `out[0] = in[99];` |

`i` doesn't exist in the hardware, and nothing iterates over time. The result is 100 wires crossing over, with no gates at all. (Vectorr's gotchas cover this procedural-loop vs. generate-loop distinction in more detail.)

## Approach 2 — `generate`-`for` loop (`alt1.v`)

```verilog
genvar i;
generate
    for (i = 0; i < 100; i = i + 1) begin : rev
        assign out[i] = in[99 - i];
    end
endgenerate
```

This looks like the same loop, but it works at a different level. A procedural `for` repeats *statements inside* an `always` block. A `generate`-`for` repeats *things that live directly in the module*: `assign` statements, module instances, declarations. Here it creates 100 continuous assignments, `rev[0]` through `rev[99]`, exactly as if you'd typed them out.

The syntax differences from the procedural loop:

- **`genvar i`** instead of `int` or `integer`. A genvar only exists during elaboration and can't be assigned inside the loop body.
- **`i = i + 1`**, since generate loops follow Verilog-2001 rules.
- **`begin : rev`** names the block. Each iteration's contents get a hierarchical name like `rev[5]`, which is what you'll see in a waveform viewer or netlist.
- **`generate` / `endgenerate`** are optional since Verilog-2005, but most codebases keep them for readability.

For this problem the two versions produce the same hardware. HDLBits suggests the `always` version because nothing here needs a generate block: generate earns its place when the loop body has to be something an `always` block can't contain, like a module instance (Module_fadd's adder chain).

## Gotchas / things I got wrong initially

- **Off-by-one indices are silent.** A quick variant is `out[100 - i] = in[i]`. At `i = 0` it writes `out[100]`, which doesn't exist, so the write is dropped with at most a warning. At `i = 99` it writes `out[1]`. So `out[0]` is never assigned, and in a combinational block an output that isn't assigned on every path is a latch (same rule as [Always_if2](../../procedures/32.%20Always_if2/README.md)). Every other bit is shifted by one. `i <= 100` causes a similar problem. Check the first and last iterations by hand: `i = 0` should hit `out[99]` and `i = 99` should hit `out[0]`.

- **`vector100r.v` is SystemVerilog, not Verilog-2001.** `always_comb`, `int` and `i++` are all SystemVerilog. HDLBits compiles as SystemVerilog, so it passes, but a strict Verilog-2001 tool rejects all three. There's also the output declaration: `out` is assigned inside a procedural block, so it should be a variable (`output logic [99:0] out` in SystemVerilog, `output reg` in Verilog), not the bare `output [99:0] out` HDLBits gives. The grader accepts the bare form, same as in Lfsr5. The generate version in `alt1.v` doesn't have this problem: it uses `assign`, so `out` is correctly a net. The same signal needs opposite declarations depending on how it's driven — the `reg` vs. net theme from the shift-register chapter.

- **The generate block needs a label.** Without `: rev` after `begin`, some tools (Quartus among them) give an error, and others make up a name like `genblk1` that's hard to find in a waveform. Always name generate blocks.

## Solution

See `vector100r.v` (procedural `for` in `always_comb`) and `alt1.v` (`generate`-`for` with continuous assignments).
