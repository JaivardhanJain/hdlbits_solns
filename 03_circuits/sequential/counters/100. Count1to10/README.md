# Count1to10

**HDLBits link:** https://hdlbits.01xz.net/wiki/count1to10
**Category:** Circuits: Sequential (Counters)
**Difficulty:** ⭐⭐

## Problem summary

Another decade counter — 10 states, period 10 — but shifted by one: it counts 1 through 10 inclusive instead of 0 through 9, and synchronous `reset` sets it to **1**, not 0.

## Approach

Structurally this is [Count10](../99.%20Count10/README.md) with every constant shifted up by one:

```verilog
always @ (posedge clk) begin
    if (reset)           q <= 4'd1;
    else if (q == 4'd10) q <= 4'd1;
    else                 q <= q + 4'd1;
end
```

Same priority chain, same terminal-count pattern — but this problem is the one where the ordering in that chain actually matters, not just as a habit. In Count10, `reset` and the terminal-count branch both happened to assign the same value (0), so getting the priority "wrong" (checking terminal count before reset) was still functionally harmless. Here they don't agree: reset assigns 1, terminal count also assigns 1 — wait, they *do* still agree, both branches land on `4'd1`. So even in this version the specific values chosen coincidentally match. The lesson is less "this problem breaks if you get it wrong" and more "the two facts (reset value, wrap-to value) are independent choices that could easily have differed" — e.g. a counter reset to `4'd1` with a *different* wrap target of `4'd0` would make branch order the difference between correct behaviour and a subtle bug when reset and terminal-count-reached happen on the same edge. Always write `reset` as the first, unconditional check out of habit, not because this specific problem's numbers force it.

The terminal value moved from **9** to **10**, because the range is now 1–10 instead of 0–9 — ten states either way, but "the last state before wrapping" shifted with the range. This is the crux of the exercise: get one endpoint right (say, keep comparing against 9 out of habit from Count10) and you silently get a period-9 or period-11 counter that still looks plausible on a quick glance.

## Gotchas / things to watch for

- **Copy-paste from Count10 without re-deriving both endpoints.** The two constants that must change together are the reset value (0→1) and the terminal-count comparison (9→10) — and it's easy to update one and miss the other, since both are "just a number" in an otherwise identical structure. Changing only the reset value gives a counter that goes 1,2,...,9,0,1,... — 10 states, but touching 0, which is outside the required 1–10 range. Changing only the terminal comparison (still resetting to 0) gives 0,1,...,10,0,... — 11 states, one too many. Whenever a problem is "the same counter, different range," treat the reset value and the wrap condition as a matched pair to re-check together, not two independent edits.

- **`4'b1` as a literal for the value 1.** It works — `4'b1` zero-extends to `4'b0001` — but it's binary radix for a decimal-sized counter, which reads oddly next to `4'b1010` for the value 10. Once a counter's terminal value isn't a nice round power-of-two/all-ones pattern, decimal (`4'd1`, `4'd10`) is more legible than reasoning through the binary. Pick one radix per file and let it match the values being expressed — binary for bit patterns and flags, decimal for a value you're going to think about as a number, which is exactly what a counter's `q` is.

- **`q + 1` (unsized) in the increment.** Same width-discipline note as [Count10](../99.%20Count10/README.md) and [Count15](../98.%20Count15/README.md): the unsized `1` is 32-bit, gets truncated to fit `q`'s 4-bit assignment target, and produces the right answer — but only because it's a direct assignment. Write `4'd1`.

- **Forgetting that "1 through 10" is still 10 states, not 11.** It's tempting to think of a 1-to-10 counter as needing more range than a 0-to-9 counter because "10 is bigger than 9" — but both cover exactly ten values; only the offset changed. The register still only needs to be 4 bits wide (0–15 range, only 10 values used), same as Count10. No extra width, no extra states — just a shifted window.

- **`output [3:0] q` without `reg`** — carried over from every counter so far: HDLBits accepts it because it compiles as SystemVerilog, but it's Verilog-2001-illegal since `q` is assigned inside an `always` block. `output reg [3:0] q`.

- **Reset-then-terminal-count branch order** — as discussed above, this problem's specific numbers don't punish getting the order wrong, but don't let that turn into a habit of deprioritizing reset. The next counter in the chapter to actually depend on this (a design where reset value ≠ wrap value) will fail silently under exactly this kind of "it worked last time" reasoning.

## Solution

See `count1to10.v`
