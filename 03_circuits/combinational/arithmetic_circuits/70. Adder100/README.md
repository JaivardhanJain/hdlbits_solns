# Adder100

**HDLBits link:** https://hdlbits.01xz.net/wiki/Adder100
**Category:** Circuits: Combinational (Arithmetic)
**Difficulty:** ⭐⭐

## Problem summary

Build a 100-bit binary adder: two 100-bit numbers `a`, `b`, and a carry-in `cin`, producing a 100-bit `sum` and a `cout`.

## Approach

Functionally this is the exact same problem as Adder3 and Exams_m2014_q4j, just 100 bits wide instead of 3 or 4. But the width change forces a real decision: Adder3 and Exams_m2014_q4j were small enough to instantiate every full adder by hand and wire the carry chain manually. Nobody is instantiating 100 full adders and hand-wiring 99 internal carry wires — that's not "more rigorous," it's just unmaintainable and a near-guarantee of a wiring typo somewhere in the chain. This is exactly the structural-vs-behavioural trade-off introduced in Exams_m2014_q4j, pushed to the point where structural stops being a reasonable option at all.

The behavioural line does the whole job:

```verilog
assign {cout, sum} = a + b + cin;
```

The reasoning is identical to Hadd, Fadd, and Adder3's `fa` leaf module, just scaled up: `a` and `b` are each 100-bit unsigned values (max `2^100 - 1`), so `a + b + cin` can reach as high as `2*(2^100 - 1) + 1`, which is exactly `2^101 - 1` — the largest value that fits in 101 bits. `{cout, sum}` is a 101-bit concatenation (1 + 100), so it's exactly wide enough to hold the full result with nothing lost, the same MSB-first carry-then-sum ordering used every other time this pattern has shown up in this chapter.

## Gotchas / things I got wrong initially

- **Reaching for a `generate`/`for` loop of 100 full adders "to be thorough."** It's a reasonable instinct after building Adder3 by hand, and it's not wrong exactly — `adder100i` later in this problem set does exactly that with a `generate for` loop. But for this problem, the hint is explicit that behavioural code is the intended solution, and it's worth internalizing why: a single arithmetic expression is trivially correct once you trust `+`, while 100 hand-wired instances (or even a generate loop you have to get the indexing right on) is 100 more places to introduce a carry-chain bug like the one flagged in Adder3. Save the structural/generate approach for when you actually need to control the resulting hardware structure.
- **Assigning `sum = a + b + cin` without the `{cout, sum}` concatenation.** Same trap as Hadd, Fadd, and every arithmetic-form solution before this one: `sum` alone is only 100 bits, so `a + b + cin` gets truncated to fit it and the carry silently disappears. At this width it's an even easier mistake to make by accident — the truncation happens the same way whether you're adding 2 bits or 200, so don't let the exercise's bigger numbers distract from the fact that it's the exact same width rule as Hadd's `sum = a + b`.
- **Confusing this `cout` with the previous problem's signed overflow.** Exams_ece241_2014_q1c spent a whole gotchas section on why a raw carry-out doesn't tell you about signed overflow. This problem is the mirror case: `a` and `b` here are being treated as plain unsigned 100-bit vectors, so `cout` genuinely is the correct "did the true sum exceed what 100 bits can represent" signal — there's no sign bit to reason about because nothing here claims to be 2's complement. Don't import q1c's "carry-out isn't the whole story" caution into a context where the numbers are unsigned and carry-out is exactly the right answer.
- **Assuming behavioural code produces worse hardware than a hand-built ripple-carry chain.** It's tempting to think `+` compiles down to the same slow, linear-delay ripple adder you'd get from chaining 100 full adders yourself — and it might, depending on the tool and constraints — but synthesis tools are generally free to (and often will) implement `+` using a faster adder architecture (carry-lookahead, carry-select, etc.) if area/timing constraints call for it. Writing structural code here doesn't just cost you development time, it can actively box the synthesizer into the exact architecture you typed instead of letting it choose a better one.

## Solution

See `adder100.v`.
