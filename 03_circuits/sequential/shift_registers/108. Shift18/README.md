# Shift18

**HDLBits link:** https://hdlbits.01xz.net/wiki/Shift18
**Category:** Circuits: Sequential (Shift Registers)
**Difficulty:** ⭐⭐

## Problem summary

A 64-bit **arithmetic** shifter with synchronous load. `amount[1:0]` picks one of four operations — left by 1, left by 8, right by 1, right by 8 — and `ena` decides whether the shift happens at all. `load` captures `data` and outranks everything. "Arithmetic" only changes the right shifts: instead of pulling in zeros, they replicate the sign bit `q[63]`, so the shifted value keeps its sign and stays a correct divide-by-2 (or divide-by-256) for two's-complement numbers.

## Approach

Structurally this is [[Rotate100]] again — clocked block, `load` first, a mode field decoded below it, and no fall-through so an idle cycle holds. The new part is the fill rule, and a `case` is the natural home for four mutually exclusive fills:

```verilog
2'b00: q <= {q[62:0], 1'b0};            // left  1: drop MSB,  append one 0
2'b01: q <= {q[55:0], {8{1'b0}}};       // left  8: drop top 8, append eight 0s
2'b10: q <= {q[63],   q[63:1]};         // right 1: drop LSB,  prepend one copy of the sign
2'b11: q <= {{8{q[63]}}, q[63:8]};      // right 8: drop low 8, prepend eight copies of the sign
```

Every line is the same two-part recipe — *the surviving slice, plus the fill* — and every line sums to 64: 63+1, 56+8, 1+63, 8+56. That arithmetic is the fastest correctness check available here, and it catches both classes of typo (wrong slice bound, wrong replication count) at once.

Note that `load` sits *outside* the `ena` test. That matches the spec — a load is not a shift, so it shouldn't require the shift enable — and the nesting says so structurally rather than relying on the reader to notice.

This chapter has now covered all three fill rules a register can use when bits move: zero-fill in [[Shift4]], wrap-around in [[Rotate100]], and sign-replication here. The plumbing is identical each time; only the source of the incoming bit changes.

## Gotchas / things to watch for

- **`>>>` does not make a shift arithmetic — the *operand's signedness* does.** The obvious-looking rewrite is a trap:
  ```verilog
  2'b10: q <= q >>> 1;              // WRONG: q is unsigned, so this is a plain logical shift
  2'b10: q <= $signed(q) >>> 1;     // right — the cast is what selects sign-extension
  ```
  In Verilog `>>>` is defined to sign-extend only when its left operand is signed; on an unsigned `reg [63:0]` it behaves exactly like `>>` and quietly shifts in zeros. Since `q` here is declared plain `reg [63:0]`, the operator version needs `$signed(...)` (or `q` declared as `reg signed [63:0]`) to do what its name suggests. The explicit concatenation sidesteps the whole question — what gets shifted in is written down, not inferred from a type. This is a close relative of the [[Step One]] lesson: results in Verilog depend on operand *properties* (width, and now signedness) that don't appear at the point of use.
- **A replication inside a concatenation needs its own braces, and the error message won't be about braces.** `{8{q[63]}}` is a complete expression: inner braces for the replication, outer braces making it a concatenation. Drop a pair and write `{8{q[63]}, q[63:8]}` and you get a syntax error at a confusing spot, because the parser is now trying to read `q[63], q[63:8]` as the thing being replicated eight times. The doubled-brace form looks like a typo and is not.
- **The slice bound and the replication count must move together, and only the width sum catches a mismatch.** For an 8-bit right shift the survivors are `q[63:8]` (56 bits) — not `q[63:7]`, and not `q[55:0]`, which is the *left*-shift slice. Getting the slice right but the count wrong (`{{7{q[63]}}, q[63:8]}`) produces a 63-bit RHS that Verilog silently zero-extends into the 64-bit register, per the resizing rule that has now caused a different silent bug in each of [[Shift4]], [[Rotate100]], and here. Add the two halves before you move on.
- **`{1'b0, q[63:1]}` is a *logical* right shift and will pass roughly half the test cases.** Every positive number shifts identically under logical and arithmetic rules; the difference only shows up once `q[63]` is 1. A testbench run that looks mostly correct with scattered failures on large values is the signature of this bug, not of a timing or priority problem.
- **There is no such thing as an arithmetic *left* shift — and left shifts destroy the sign bit.** Both left modes fill with zeros because there's nothing meaningful to replicate at the LSB end. The consequence worth knowing: shifting left pushes `q[63]` off the top, so a positive number can become negative (and vice versa) after one left shift. That's ordinary two's-complement overflow, not a bug in the shifter, but it means left-then-right does not round-trip.
- **All four `amount` codes are covered, so nothing is left implicit — but the reason a missing case would be safe here is worth being precise about.** In a *combinational* block, an unhandled case value infers a latch; inside `always @(posedge clk)` it just means "no assignment this cycle," i.e. hold — the same rule as the missing `else` in [[Shift4]]. A `default:` is still good practice for wider selectors, and mandatory the moment this logic moves into a combinational block. The related habit: since `amount` is a full 2-bit encoding with every value assigned a meaning, list all four explicitly rather than folding two of them into a `default` where a spec change would hide.
- **The nested `else begin if (ena) ... end` is correct but says less than `else if (ena)`.** Two levels of `begin`/`end` to express one extra condition invites a later editor to add a statement at the wrong nesting level. Flattening it to `else if (ena) case (amount) ... endcase` is the same hardware and matches the priority-chain shape used in [[Shift4]] and [[Rotate100]], so the whole chapter reads consistently.
- **No reset here either, and this register only *half* flushes itself.** As in [[Rotate100]], the flops power up as `x` and `load` is the only guaranteed initialization. Left shifts do inject known zeros, so 64 enabled left-by-1 cycles would clean it out — but the right shifts feed `q[63]` back into the register, so an `x` in the sign bit reproduces itself indefinitely. Don't assume "it'll shift itself clean."
- **`q` needs `output reg`** — assigned procedurally; see [[Dff8ar]] for why HDLBits's bare declaration compiles regardless.

## Solution

See `shift18.v`.
