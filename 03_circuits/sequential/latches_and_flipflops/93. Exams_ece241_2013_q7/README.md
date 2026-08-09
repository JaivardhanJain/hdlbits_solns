# Exams_ece241_2013_q7

**HDLBits link:** https://hdlbits.01xz.net/wiki/exams/ece241_2013_q7
**Category:** Circuits: Sequential (Latches and Flip-flops)
**Difficulty:** ⭐⭐⭐

## Problem summary

Build a **JK flip-flop** out of nothing but a D flip-flop and combinational gates, matching this truth table (`Qold` is `Q`'s value just before the clock edge):

| J | K | Next `Q` |
|:---:|:---:|---|
| 0 | 0 | `Qold` (hold) |
| 0 | 1 | 0 (reset) |
| 1 | 0 | 1 (set) |
| 1 | 1 | `~Qold` (toggle) |

## Approach

A JK flip-flop is really just a D flip-flop with translation logic in front of it: whatever `d` needs to be to make `Q` land on the right row of the table, computed combinationally from `j`, `k`, and the flop's *current* output `Q`. That's the whole circuit — one clocked block for the flop, one combinational block that implements the table above as a `case`.

```verilog
always @ (posedge clk) begin
    Q <= d;
end

always @ (*) begin
    case ({j, k})
        2'b00 : d = Q;      // hold
        2'b01 : d = 1'b0;   // reset
        2'b10 : d = 1'b1;   // set
        2'b11 : d = ~Q;     // toggle
    endcase
end
```

### The `case` statement

`case (expr) value1: stmt1; value2: stmt2; ... endcase` compares `expr` against each listed value in order and executes the statement next to the first match — functionally a chain of `if / else if` where every branch tests the same expression for equality. It reads better than the `if` form when there's one signal being tested against several possible values, which is exactly this situation: four rows of a truth table, one governing expression.

### `{j, k}` — concatenation as a truth-table index

`{j, k}` is the concatenation operator from [[Vector3]], applied here to two independent scalar inputs rather than pieces of a vector. `j` and `k` aren't naturally one signal — they're two separate ports — but concatenating them on the fly builds exactly the 2-bit value the truth table is indexed by, `2'b`*jk*, without declaring an intermediate wire just to hold it. `case ({j,k})` then matches `2'b00`, `2'b01`, `2'b10`, `2'b11` directly against the rows of the spec table above, so the code and the table read in the same order.

The alternative — nested `if (j) ... else ... if (k) ...` — works too, but obscures the fact that this is fundamentally a 4-row lookup on a single combined value. Concatenating the selector to match the shape of the spec is worth recognizing as a general technique, not just a trick for this problem.

### Why `Q` is clocked but `d` is combinational

This is the same "next-state logic + state register" split as [[Mt2015_muxdff]] and [[Exams_2014_q4a]], but it's worth spelling out precisely *why* the split has to work this way for a JK flop specifically.

`Q` is the flip-flop's actual stored state — the thing that has to persist between clock edges and only change *at* a clock edge, which is exactly what `always @(posedge clk)` gives you. `d`, on the other hand, isn't state at all; it's a continuously-recomputed answer to the question "given the current inputs and the current `Q`, what should the *next* `Q` be?" That answer has to be ready and stable by the time the clock edge arrives, which means it has to update immediately whenever `j`, `k`, or `Q` changes — combinational behaviour, `always @(*)`.

Notice `d`'s own definition depends on `Q` (rows 0 and 3 of the table read `Q` back). That's legal and is not the same thing as the flop reading its own output inside its own clocked block ([[Exams_m2014_q4d]]'s pattern) — here, `Q` is read by a *separate* combinational block to help decide the *next* value, and that next value is registered by the clocked block afterward. The flop only ever sees the finished answer, `d`, once per clock edge; it never needs to know or care that `d` was partly built out of its own current value.

## Gotchas / things to watch for

- **`d` must be `reg`, not `wire`.** It's assigned inside `always @(*)`, so it needs to be a variable, not a net — the same rule from [[Mt2015_muxdff]] and [[Exams_2014_q4a]]. This is a hard compile error, not a style note.
- **`case` requires exact bit-for-bit matching, including width.** `case ({j,k})` compares a genuine 2-bit value against `2'b00` etc.; if you instead wrote `case(j,k)` (a syntax error — `case` takes one expression) or matched against unsized `0`/`1`/`2`/`3`, the comparison would still probably work here since Verilog zero-extends for comparison, but it's fragile: get the concatenation width wrong elsewhere and a case that "looks like" it covers every value can silently stop matching. Match the case expression's width to the literals you're comparing it to.
- **This `case` happens to be exhaustive, so there's no latch risk — but only because 2 bits genuinely have exactly 4 combinations.** `{j,k}` covers `00`/`01`/`10`/`11` with nothing left over, so every simulation value except `x`/`z` is handled and `d` is never left unassigned. That's a property of this specific case statement, not of `case` in general — a `case` on a wider or don't-care-laden selector can leave gaps exactly like an incomplete `if` can (see [[Mt2015_muxdff]]'s `default` gotcha), and it's worth checking exhaustiveness explicitly rather than assuming a `case` block is automatically safe just because it's a `case`.
- **Row order in the table has to survive translation into code without getting scrambled.** It's easy to transpose two rows while typing a truth table out — swap the `2'b01`/`2'b10` bodies here and you get a JK flop with reset and set reversed, which still compiles, still looks structurally right, and only disagrees with the spec on two of the four input combinations. Cross-check each `case` branch against its row in the table by eye before moving on, not just by "does it compile."
- **`Q` needs `output reg`.** Same note as every clocked-output problem in this chapter — see [[Dff8ar]] for why HDLBits's bare `output Q` compiles anyway.

## Solution

See `exams_ece241_2013_q7.v`.
