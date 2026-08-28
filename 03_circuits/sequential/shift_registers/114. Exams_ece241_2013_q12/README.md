# Exams_ece241_2013_q12

**HDLBits link:** https://hdlbits.01xz.net/wiki/Exams/ece241_2013_q12
**Category:** Circuits: Sequential (Shift Registers)
**Difficulty:** ⭐⭐⭐

## Problem summary

An 8×1 memory that is *written* serially and *read* randomly: eight flip-flops form a shift register that `S` fills one bit per enabled clock, and three address inputs `A`, `B`, `C` select which stored bit appears on `Z`. The constraint is that the circuit contain nothing but the shift register and multiplexers. Put that way it sounds like two unrelated blocks bolted together — and then you notice what it adds up to. A 3-input truth table, loaded serially, read combinationally, is exactly a **3-input look-up table**: the primitive an FPGA is built out of.

## Approach

The two halves are written in the two different styles they belong to, in one module.

The write side is an ordinary enabled shift register, the same shape as everything else in this chapter:

```verilog
always @(posedge clk) begin
    if (enable)
        q <= {q[6:0], S};   // S enters at q[0]; contents move toward the MSB
end
```

The read side is one line, and it is the whole 8-to-1 mux:

```verilog
assign Z = q[{A, B, C}];
```

`{A, B, C}` concatenates the three address bits into a 3-bit number, and indexing a vector with a *non-constant* expression is a **variable bit-select** — legal Verilog that synthesizes to a mux tree. There is no loop, no `case`, and no generate: the address arithmetic that a case statement would spell out in eight branches is already implicit in what "index a vector" means. It satisfies the "only muxes" constraint literally, since a variable bit-select is a mux and nothing else.

Worth naming why the two halves are written differently. `q` is state, updated on a clock edge, so it lives in an `always @(posedge clk)` block with non-blocking assignment. `Z` is a pure function of `q` and the address, with no memory of its own, so it's a continuous assignment. The two coexist without interacting: the mux reads `q` combinationally at the same time the clocked block is driving it, which is exactly what a real LUT does.

The equivalent explicit mux, for comparison:

```verilog
always @(*) begin
    case ({A, B, C})
        3'd0: Z = q[0];
        3'd1: Z = q[1];
        // ... six more
    endcase
end
```

Eight lines, eight chances to mistype an index, and it *requires* `Z` to be a `reg` — which is where the declaration issue below comes from.

## Gotchas / things to watch for

- **`output reg Z` combined with `assign Z = ...` is illegal Verilog-2001, and HDLBits's own header doesn't ask for it.** The problem gives `output Z`; the `reg` is an addition. A continuous assignment must drive a **net**, and `reg` declares a variable — in strict Verilog-2001 this combination is a compile error. It passes the grader only because HDLBits compiles as SystemVerilog, which does permit a single continuous assignment to a variable. Deleting the word `reg` makes it portable and changes nothing else. This is the mirror image of the [[Lfsr5]] and [[Mt2015_lfsr]] situation, where HDLBits's provided header *omitted* a `reg` that a procedural assignment required — and the confusion has a clear source: the `case`-statement version of this mux **does** need `output reg Z`, because there the assignment is procedural. Same output, same hardware, opposite declaration, decided entirely by which construct drives it. If there's one rule to carry out of this chapter, it's that one.
- **`{A, B, C}` puts `A` in the most significant position — reverse it and the LUT is silently wired to the wrong truth table.** `{C, B, A}` compiles, synthesizes, and produces a circuit that reads bit 6 when you asked for bit 3. Nothing in the language knows which order the problem meant; the spec's `ABC=001 → Q[1]` is the only thing that pins it down. The failure mode is especially nasty here because the circuit is a *memory*: it will faithfully return whatever bit it thinks you addressed, so it looks like a data problem rather than a wiring problem.
- **A variable bit-select is a mux, not an array lookup — and it costs real gates.** `q[{A,B,C}]` looks like `q` is being indexed the way software indexes an array, which invites the assumption that it's free. It synthesizes to a 7-mux tree (three levels), and the same syntax on a 1024-bit vector would build a 1023-mux tree. Convenient notation, real hardware; that's why it's worth knowing what it expands to.
- **If any of `A`, `B`, `C` is `x`, the index is `x` and `Z` comes back `x`** — not 0, and not the "closest" bit. Combined with the point below, an unsimulated waveform full of red on `Z` may be an addressing problem rather than a memory-contents problem. (An out-of-range index would also give `x`, though with a 3-bit address and an 8-bit vector that can't happen here.)
- **There is no reset, so the memory holds `x` until it has been written eight times.** The eight flops power up undefined and only known bits entering via `S` displace them, one per enabled clock. That's a faithful model of a real write-before-read memory rather than a bug, but it means "the LUT outputs `x`" is the expected behaviour for the first eight enabled cycles, and reading before writing is a design error at the *system* level with nothing in this module to catch it. Same family as [[Rotate100]] and [[Exams_2014_q4b]], where a load is the only initialization — here even that is serial.
- **`enable` gates the shift by omitting the assignment, not by gating the clock.** No `else` means hold, which synthesizes to a clock enable on the flops — the [[Shift4]] rule, and the correct alternative to the clock-gating hazard flagged in [[Countslow]]. Note also that `enable` has no effect on reads: `Z` tracks `q` and the address continuously, so the memory is readable on every cycle including ones where it isn't being written.
- **The shift direction and the spec's bit labelling have to agree, and only the spec settles which is which.** `{q[6:0], S}` sends `S` into `q[0]` and pushes contents toward `q[7]`, matching "S feeds Q[0]". Writing `{S, q[7:1]}` instead is an equally valid shift register that loads the truth table in reverse order, so every subsequent read is wrong. Same trap as the shift-direction note in [[Mt2015_lfsr]] — derive it from the figure, not from the previous problem's shape.
- **This is not a toy: it's how an FPGA's own logic is configured.** A LUT in a real FPGA is exactly this — a small memory holding a truth table, read combinationally by the "address" formed from the logic inputs, and loaded through a long serial configuration chain at power-up. The bitstream you download to a board is, in large part, `S` for millions of copies of this circuit. Recognizing the pattern is most of the value of this problem.

## Solution

See `exams_ece241_2013_q12.v`.
