# Countbcd

**HDLBits link:** https://hdlbits.01xz.net/wiki/countbcd
**Category:** Circuits: Sequential (Counters)
**Difficulty:** ⭐⭐⭐

## Problem summary

Build a 4-digit BCD counter: `q[3:0]` is the ones digit, `q[7:4]` tens, `q[11:8]` hundreds, `q[15:12]` thousands — 0000 through 9999. For the upper three digits, also expose an `ena[3:1]` output showing when each digit is enabled, so the ripple-enable logic can be checked directly.

## Approach

This is [Exams_ece241_2014_q7b](../103.%20Exams_ece241_2014_q7b/README.md) again — same ripple-carry-shaped enable chain, one more digit — but two things are different, and both matter:

```verilog
assign ena[1] = (q[3:0]  == 4'd9);
assign ena[2] = (q[3:0]  == 4'd9) && (q[7:4]  == 4'd9);
assign ena[3] = (q[3:0]  == 4'd9) && (q[7:4]  == 4'd9) && (q[11:8] == 4'd9);

bcdcounter counter0 (.clk(clk), .reset(reset), .enable(1'b1),   .Q(q[3:0]));
bcdcounter counter1 (.clk(clk), .reset(reset), .enable(ena[1]), .Q(q[7:4]));
bcdcounter counter2 (.clk(clk), .reset(reset), .enable(ena[2]), .Q(q[11:8]));
bcdcounter counter3 (.clk(clk), .reset(reset), .enable(ena[3]), .Q(q[15:12]));
```

**First: `q` is one packed 16-bit bus, not an unpacked array of four registers.** Exams_ece241_2014_q7b's `Q[2:0]` was an array because there was no reason to treat the three digits as one combined value — nothing in that circuit read "the whole number" at once. Here, the module interface *is* a single 16-bit `q`, sliced with part-selects (`q[3:0]`, `q[7:4]`, ...) to address each digit — because the problem statement defines the digits as sub-ranges of one bus, not as separate signals. Same BCD idea, different packing decision, driven by what the interface actually asks for rather than a fixed rule.

**Second: `ena[1]`'s condition is written out in full (`q[3:0] == 4'd9`) instead of reused from a wire, and `ena[2]`/`ena[3]` repeat their prerequisite conditions rather than building on `ena[1]`/`ena[2]` directly** — this version writes `ena[2] = (q[3:0]==9) && (q[7:4]==9)` instead of `ena[2] = ena[1] && (q[7:4]==9)`. Both are logically identical (`ena[1]` *is* `q[3:0]==9`, so substituting the definition back in changes nothing), but the second form is shorter, self-documenting as "carry chain," and only computes the ones-digit comparison once in the actual gate-level netlist instead of duplicating it — most synthesis tools will common-subexpression-eliminate this back to the same hardware either way, but writing it as `ena[2] = ena[1] && (q[7:4]==9)` doesn't rely on the tool to notice the duplication, and reads directly as "tens carries when ones carries and tens is also at 9." Either form is acceptable; the `ena[1]`-reuse form is the more scalable pattern once you're chaining more than two or three stages (see `alt1.v`'s generate loop in [Bcdadd4](../../combinational/arithmetic_circuits/71.%20Bcdadd4/README.md) for what happens when a repeated hand-written pattern needs to scale further).

**`ena[0]` doesn't exist — the ones digit's enable is hardwired to `1'b1` at the instantiation site, not exposed as an output.** The module declaration is `output [3:1] ena`, three bits, indices 3 down to 1 — there is no `ena[0]` port at all, which matches the fact that the ones digit's enable was never in question: it counts every cycle, unconditionally, same as `c_enable[0]` in the previous problem. The `[3:1]` range in the port declaration is doing real work here, not just an arbitrary numbering choice.

Because this problem's `bcdcounter` isn't provided by HDLBits (the hint says "you may want to instantiate or modify" a decade counter — you're expected to write it, unlike `count4`/`bcdcount` in the previous two problems), it's included directly in this solution file, in the same style as `fa` in [Adder3](../../combinational/arithmetic_circuits/67.%20Adder3/README.md).

## Gotchas / things to watch for

- **Premature reset — folding the terminal-count wrap into the same condition as `reset`, without gating it by `enable`.** A tempting "simplification" of `bcdcounter` looks like this:

  ```verilog
  always @ (posedge clk) begin
      if (reset || Q == 9) Q <= 0;
      else if (enable) Q <= Q + 1;
  end
  ```

  It reads as a natural merge — "reset to 0 whenever we hit reset, *or* whenever we've hit the terminal count" — and it's wrong for exactly the reason [Countslow](../101.%20Countslow/README.md) and [Exams_ece241_2014_q7a](../102.%20Exams_ece241_2014_q7a/README.md) both flagged: `Q == 9` on its own says nothing about whether this digit is actually supposed to be advancing this cycle. With `enable` low, a real digit sitting at 9 must *hold* at 9 — that's the entire meaning of a disabled counter — but this version zeroes it out on the very next clock edge regardless, because the `Q == 9` clause sits in the same unconditional `if` as `reset`, outside the `enable` check entirely. The bug is quiet: in the always-enabled ones digit (`counter0`, wired to `enable = 1'b1`) it's invisible, since that digit is never supposed to hold anyway — the corruption only shows up in `counter1`–`counter3`, and only during the many cycles where they're legitimately disabled and sitting at 9 waiting for a carry in. The fix is what the original block already did: keep the terminal-count check *inside* the `enable` branch, not merged into the reset condition —

  ```verilog
  if (reset)          Q <= 0;
  else if (enable) begin
      if (Q == 9)      Q <= 0;
      else             Q <= Q + 1;
  end
  ```

  — reset and "wrap because I'm enabled and at 9" are two different reasons to zero the register, and only one of them is allowed to fire when `enable` is low.

- **Forgetting the `&& (q[7:4]==9)` term when writing `ena[3]`, by analogy with `ena[2]`.** Same ripple-carry trap as `c_enable[2]` in Exams_ece241_2014_q7b: the thousands digit needs *every* lower digit to be simultaneously at its terminal value and *actually carrying*, not just the ones digit. `ena[3] = (q[3:0]==9)` alone (missing the tens and hundreds terms) would make the thousands digit increment every time the ones digit merely reads 9 — vastly too often.

- **Wiring `counter0`'s `enable` to something other than a hardwired `1'b1`.** It's easy, especially copy-pasting the other three instantiations, to accidentally give the ones digit a conditional enable (or worse, leave it unconnected, which floats and won't count at all in real hardware, or defaults to `x`/`z` and misbehaves in simulation depending on the tool). The ones digit's enable isn't computed from anything — it's a constant, by definition of being the fastest-moving digit.

- **Positional vs. named instantiation** — carried over from every "instantiate a counter submodule" problem this chapter: `bcdcounter counter1(clk, reset, ena[1], q[7:4]);` works only because the port order happens to match, and named connections remove that fragility.

- **`q[3:0] == 9` (unsized) instead of `4'd9`** — the same standing width-hygiene note repeated through this entire chapter; harmless here, but worth staying consistent about.

## Solution

See `countbcd.v`
