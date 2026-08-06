# Exams/ece241_2014_q1c (Signed addition overflow)

**HDLBits link:** https://hdlbits.01xz.net/wiki/Exams/ece241_2014_q1c
**Category:** Circuits: Combinational (Arithmetic)
**Difficulty:** ⭐⭐⭐

## Problem summary

`a[7:0]` and `b[7:0]` are two 8-bit 2's complement (signed) numbers. Add them to produce `s[7:0]`, and also compute `overflow`: whether that addition overflowed the range a signed 8-bit number can represent.

## Approach

The sum itself is the easy part — `s = a + b`, same as every other adder in this chapter. The interesting part is `overflow`, and it's worth working out the logic by hand before looking at the code, because the equation only makes sense once you've reasoned through *when* signed overflow can actually happen.

Start from the definition: a signed overflow happens when adding two positive numbers produces a negative result, or adding two negative numbers produces a positive result. Notice what's missing from that list — adding a positive number and a negative number is never mentioned, and that's not an oversight. If `a` and `b` have opposite signs, the true sum always lies between them in value, which means it can never leave the representable range in either direction. **Opposite-sign addition cannot overflow, full stop.** That's the first branch of the logic: if `a[7] != b[7]` (signs differ), `overflow` is unconditionally 0 — there's nothing left to check.

That leaves the same-sign case. If `a` and `b` share a sign, the mathematically correct sum must also share that sign — two positives can't sum to something negative, two negatives can't sum to something positive, unless the result wrapped around the representable range. So when `a[7] == b[7]`, overflow occurred exactly when the result's sign (`s[7]`) doesn't match the shared input sign (`a[7]`).

Putting those two branches together is exactly what the nested ternary does:

```verilog
assign overflow = a[7] ^ b[7] ? 0 : a[7] ^ s[7] ? 1 : 0;
```

Read outer to inner: "if the signs of `a` and `b` differ, no overflow; otherwise, overflow iff `a`'s sign differs from `s`'s sign." `alt1.v` expresses the identical condition as a single boolean equation instead of a branch: `overflow = ~(a[7] ^ b[7]) & (a[7] ^ s[7])` — "signs match, AND the result's sign doesn't."

## Gotchas / things I got wrong initially

- **Dropping the `[7]` index and comparing whole vectors instead of just the sign bits.** My first attempt at this had a typo where I wrote `a ^ b` instead of `a[7] ^ b[7]` in the ternary condition. That's an 8-bit XOR, not a 1-bit one — and Verilog happily accepts a multi-bit value as a ternary/if condition, treating it as "true if any bit is nonzero." So instead of asking "do the sign bits differ?", the circuit was actually asking "do `a` and `b` differ in *any* bit position at all?" — which is true for almost every input pair, not just the ones with mismatched signs. It compiled cleanly and simulated without any error message, and just quietly produced wrong overflow values for nearly every test case. Nothing about the syntax flags this as wrong; you have to know that a bare `a` here means "all 8 bits" and catch the missing index yourself.
- **Indexing one operand and forgetting the other.** A related version of the same mistake: writing `a[7] ^ s` (indexing `a` correctly but forgetting to index `s`) or `a ^ s[7]` (the other way round). When one side of a bitwise `^` is 1 bit and the other is 8 bits, Verilog zero-extends the narrower operand up to match the wider one before comparing — so `a ^ s[7]` really computes `a ^ {7'b0, s[7]}`, which only touches bit 0 of `a` and leaves bits `a[7:1]` untouched in the result. The resulting 8-bit value gets reduced to a boolean the same way as above, and again there's no compiler error — just a circuit that's checking something almost, but not quite, unrelated to what you meant to check. The fix in both cases is the same: overflow logic here only ever cares about three specific single bits (`a[7]`, `b[7]`, `s[7]`), so every operand in that expression should be an explicitly indexed single bit — never a bare vector name.
- **Confusing signed overflow with the unsigned carry-out.** Earlier problems in this chapter (Adder3, Exams_m2014_q4j) expose an explicit `cout` — the carry out of the top bit — as the thing to watch for arithmetic overflow. That's correct for *unsigned* addition, but it doesn't directly apply here: this problem doesn't even give you a 9th output bit to see a carry-out on, and signed overflow is a different condition entirely (it's about the sign bit lying about the true result, not about a bit falling off the top). Reaching for "just check if it carried out of bit 7" here would either not compile (there's no such signal exposed) or, if hand-rolled from an internal carry chain, would answer the wrong question for signed numbers.
- **Trying to special-case the opposite-sign inputs "just to be safe."** It's tempting, especially before you've convinced yourself of the proof above, to add extra logic handling `a[7] != b[7]` as if it might also produce overflow under some condition. It can't — the outer ternary's `0` branch isn't a shortcut or an approximation, it's the actual complete answer for that case. Adding logic there doesn't fix a bug, it just adds gates that can never affect the (already correct) output.

## Solution

See `exams_ece241_2014_q1c.v` for the nested-ternary form, and `alt1.v` for the equivalent single boolean-equation form.
