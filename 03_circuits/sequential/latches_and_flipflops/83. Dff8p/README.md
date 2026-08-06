# Dff8p

**HDLBits link:** https://hdlbits.01xz.net/wiki/dff8p
**Category:** Circuits: Sequential (Latches and Flip-flops)
**Difficulty:** ⭐⭐

## Problem summary

Eight D flip-flops sharing one clock and one active-high **synchronous** reset, but with two twists compared to [[Dff8r]]: the reset value is `0x34` instead of zero, and the flops trigger on the **falling** edge of `clk`.

## Approach

Structurally identical to Dff8r — one `always` block, one non-blocking assignment per branch, the vector width doing the work of instantiating all 8 flops. Only two things change:

- The sensitivity list becomes `always @(negedge clk)`.
- The reset branch loads a constant other than zero: `q <= 8'h34;`.

Because the reset is synchronous, it still lives entirely inside the clocked block as an `if` condition — nothing about "preset" changes that.

## Gotchas / things to watch for

- **Read the edge before you type `posedge`.** After three problems in a row that all used `always @(posedge clk)`, `posedge` is pure muscle memory, and nothing about this problem *looks* different enough to break the habit. The spec asks for the negative edge, and a `posedge` version still simulates cleanly and still looks like a flip-flop — it just samples `d` half a cycle early, so it fails the grader on timing rather than on structure. This is also why real designs standardize on a single clock edge across a whole block: every negedge flop in a mostly-posedge design creates a half-cycle timing path that static timing analysis has to treat specially, and it's a classic source of hold-time violations at block boundaries. Using `negedge` here is following the spec, not general good practice.
- **`8'h34` is not `34`.** Writing `q <= 34;` gives you decimal 34 = `8'b0010_0010` = `0x22`, silently, with no warning — the literal is legal, it's just the wrong number. This is the sized-literal discipline from [[Step One]] (`1` vs `1'b1`) showing up in a form where the width is fine and only the *radix* is wrong, which is harder to spot. Always write reset constants with an explicit width and base (`8'h34`), and match the base the spec used so you can eyeball the two against each other.
- **"Preset" is a name for the value, not for the timing.** The HDLBits hint mentions that resetting a register to 1 is sometimes called a *preset*, and in a data book "preset" and "clear" are typically the **asynchronous** set/clear pins on a flip-flop. That association tempts you into `always @(negedge clk or posedge reset)`. This problem is still a synchronous reset, so `reset` stays out of the sensitivity list for exactly the reason given in [[Dff8r]] — putting it there builds a different circuit that happens to pass some of the same test vectors.
- **A non-zero reset value is ordinary logic, not a special flop.** `8'h34` = `8'b0011_0100`, so bits 2, 4 and 5 reset high and the rest reset low. Because the reset is synchronous, none of this reaches the flop's own set/clear pins at all — the synthesizer just builds a mux on the D input that selects the constant when `reset` is high, and every bit gets the same flop. It's worth internalizing the contrast: had this been an *asynchronous* preset to `0x34`, the tool would have had to map the design onto a mix of async-set and async-clear flop primitives, which on many FPGA families is a real constraint (some architectures only offer one polarity per clock region, and asking for both forces extra logic).
- **Keep `<=` on both branches.** Same rule as [[Dff8r]]: the reset branch feels like "assigning a constant" and invites a blocking `=`, but both branches update the same register on the same edge and both need the non-blocking form.

## Solution

See `dff8p.v`.
