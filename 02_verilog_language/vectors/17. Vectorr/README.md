# Vectorr

**HDLBits link:** https://hdlbits.01xz.net/wiki/Vectorr
**Category:** Verilog Vectors
**Difficulty:** ⭐

## Problem summary

Given an input vector, reverse the bits and output the new vector.


## Approach

Use the concatenation operators.

## Gotchas / things I got wrong initially
 - A procedural `for` loop (inside `always @(*)`) describes *behavior*, not *structure* — it can only appear inside a procedural block. The loop itself doesn't exist in the resulting hardware; the synthesizer unrolls it at compile time into the same fixed set of wires/gates you'd get from writing out each iteration by hand. A simulator, by contrast, actually executes it sequentially at simulation time — same end result, different mechanism. Use `integer` for the loop variable in plain Verilog (`int` is SystemVerilog-only).
 - A `generate`-`for` loop is conceptually different even though it looks similar: it's not describing an action, it's stamping out multiple copies of things you could otherwise only write outside a procedural block — `assign` statements, module instances, declarations. It's evaluated entirely at compile time, `genvar`s are read-only inside the loop body, and some tools (e.g. Quartus) require the loop body wrapped in a named `begin`/`end` block.
 - Both loop styles are overkill for this problem — manual concatenation is simpler at 8 bits and that's what `vectorr.v` uses. Loops earn their keep once the vector gets wide or parameterized (see `vector100r` later in the series), where writing out every bit by hand stops being practical.

## Solution

See `vectorr.v`
