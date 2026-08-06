# Exams/ece241 2013 q2

**HDLBits link:** https://hdlbits.01xz.net/wiki/Exams/ece241_2013_q2
**Category:** Circuits: Combinational (Karnaugh Map to Circuit)
**Difficulty:** ⭐⭐⭐

## Problem summary

A 4-input (`a,b,c,d`), single-output system outputs 1 for the numbers 2, 7, and 15, outputs 0 for 0, 1, 4, 5, 6, 9, 10, 13, and 14, and never sees the numbers 3, 8, 11, or 12 (don't-cares — see [[Kmap3]] for what that means and how to use them). Unlike [[Kmap1]]–[[Kmap4]], which hand you a pre-drawn map, this problem hands you the spec as plain numbers and two required outputs: `out_sop` in minimum SOP form and `out_pos` in minimum POS form, built from the same map.

## SOP vs. POS, concretely

Both are ways of writing the exact same boolean function; they differ in which cells of the map you group and what you do with the result.

**Sum of products (SOP)** groups the **1-cells** (and any don't-cares worth folding in) into rectangles, same as every problem in this chapter so far. Each group becomes one AND term (a "product"); the terms are OR'd together (a "sum"). It directly answers "which input patterns make the output 1?"

**Product of sums (POS)** groups the **0-cells** (and don't-cares) instead. Each group of 0s corresponds to an input pattern the *output rules out* — for example, a group covering every cell where `a=1,d=0` means "whenever `a=1` and `d=0`, output is 0," i.e. output can only be 1 if `~a | d` holds. Complementing that group's term (via De Morgan) turns "AND of literals that's 0 here" into "OR of the complemented literals that must hold for output to be 1." Those OR terms are then AND'd together (a "product of sums"). It directly answers "which input patterns must the output rule out?" — the dual framing of SOP.

They're never in conflict — a cell that's a genuine 1 in the map is a 1 under both readings, and a genuine 0 is a 0 under both. Don't-cares are the only place SOP and POS can *legitimately* resolve differently between each other, since each form is free to assign its own don't-cares however best shrinks its own groups.

## Approach: truth table → K-map → equations → HDL

**1. Truth table.** The problem statement already gives this as a list rather than a table: decimal inputs 2, 7, 15 → `out=1`; 0, 1, 4, 5, 6, 9, 10, 13, 14 → `out=0`; 3, 8, 11, 12 → don't-care. Reading each number as 4 bits `a,b,c,d` (MSB first, as the problem's own example — "7 corresponds to a,b,c,d = 0,1,1,1" — confirms) is what turns this into a truth table over 4 variables.

**2. K-map.** Laying that truth table out as a 4-variable map (rows `ab`, columns `cd`, both Gray-coded `00,01,11,10` — see [[Kmap1]] for why Gray code, [[Kmap2]] for how the edges wrap):

| ab \ cd | 00 | 01 | 11 | 10 |
|---|---|---|---|---|
| **00** | 0 | 0 | x | 1 |
| **01** | 0 | 0 | 1 | 0 |
| **11** | x | 0 | 1 | 0 |
| **10** | x | 0 | x | 0 |

**3. Equations.**

*SOP* — group the 1s and useful don't-cares: the entire `cd=11` column (`c=1,d=1` — minterms 3, 7, 11, 15, all 1 or `x`) forms a size-4 group, giving the term `c & d`. That alone covers both real 1s at 7 and 15, but not the one at minterm 2 (`a=0,b=0,c=1,d=0`). A second group — `ab=00` row, `cd=10` and `cd=11` columns (`a=0,b=0,c=1`, minterms 2 and 3) — picks that up, giving `~a & ~b & c`. Summed: `out_sop = (c & d) | (~a & ~b & c)`.

*POS* — group the 0s and useful don't-cares instead: the whole `c=0` half of the map (columns `cd=00,01`, all rows — minterms 0,1,4,5,6,8,9,12,13, every one a 0 or `x`) is a size-8 group, whose corresponding factor is `(c)` (output can't be 1 unless `c=1`). The `a=1,d=0` region (columns `cd=00,10`, rows `ab=10,11` — minterms 8,10,12,14) is another all-0-or-`x` group, giving the complemented factor `(~a | d)`. The `b=1,d=0` region (columns `cd=00,10`, rows `ab=01,11` — minterms 4,6,12,14) gives `(~b | d)`. AND'd together: `out_pos = (c) & (~a | d) & (~b | d)`.

**4. HDL.** Each equation becomes one `assign` — `out_sop` and `out_pos` are independent outputs of the same module, not two attempts at the same wire, since the problem wants both forms produced side by side.

## Gotchas / things to watch for

- **Assuming SOP and POS must land on identical minimum expressions.** They're logically equivalent as *functions*, but the two expressions here don't look alike at all (2 terms of 2–3 literals vs. 3 terms of 1–2 literals) — that's expected, not a sign one of them is wrong. [[Kmap1]] was a special case where they happened to coincide; that's the exception, not the rule.
- **Resolving the same don't-care inconsistently within one expression.** Minterm 3 gets folded into *both* SOP groups above (`c&d` and `~a&~b&c` both happen to cover it) — that's fine, groups are allowed to overlap. What would be wrong is deriving `out_sop` as if minterm 3 were a 1, then separately deriving `out_pos` from a version of the map where minterm 3 is a 0 and calling it the same problem's solution — each output can resolve its own don't-cares as it likes, but do so deliberately, not by losing track of which cells you've called 1 vs. 0 partway through the grouping.
- **Forgetting that a whole-row or whole-column group is still just a group.** The `c=0` group spanning all 8 cells in the left half of the map is easy to overlook as "too big to be a real group" — but any power-of-two rectangle is legal, including ones that span the entire map minus nothing at all (here, exactly half).
- **Bitwise vs. logical operators, as in every problem in this chapter.** `&`, `|`, `~` are correct for single-bit signals; `&&`, `||`, `!` would happen to produce the same simulation result here but are semantically the wrong operators for combining individual bits.

## Solution

See `exams_ece241_2013_q2.v`.
