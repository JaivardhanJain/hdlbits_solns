# Kmap2

**HDLBits link:** https://hdlbits.01xz.net/wiki/Kmap2
**Category:** Circuits: Combinational (Karnaugh Map to Circuit)
**Difficulty:** ⭐⭐⭐

## Problem summary

Same task as [[Kmap1]], scaled up to 4 variables: implement the circuit described by a given Karnaugh map over inputs `a`, `b`, `c`, `d`. Same instruction too — simplify before coding, and try both SOP and POS.

## The map, laid out

A 4-variable K-map needs two variables on each axis instead of one. The standard layout puts `a,b` on the rows and `c,d` on the columns, both Gray-coded (`00, 01, 11, 10`, per [[Kmap1]]'s explanation of why it has to be Gray code and not binary order). Reading off this problem's map cell by cell:

| ab \ cd | 00 | 01 | 11 | 10 |
|---|---|---|---|---|
| **00** | 1 | 1 | 0 | 1 |
| **01** | 1 | 0 | 1 | 1 |
| **11** | 0 | 0 | 1 | 0 |
| **10** | 1 | 1 | 1 | 0 |

10 of the 16 cells are 1. The largest groupings available are all size-4 or size-2 — there's no single size-8 group possible here, since the 1s aren't clustered that densely.

## Grouping it

- **`ab=00,01` rows × `cd=00,10` columns → `~a & ~d`.** Both rows have `a=0`; both columns have `d=0` (`cd=00` and `cd=10` both end in `0`). `b` and `c` vary freely across the group and drop out, leaving just `a'd'`.
- **`ab=00,10` rows × `cd=00,01` columns → `~b & ~c`.** Both rows have `b=0` (`ab=00` and `ab=10` both start with `0`); both columns have `c=0`. `a` and `d` drop out, leaving `b'c'`.
- **`ab=10` row × `cd=01,11` columns → `a & ~b & d`.** Only one row (`a=1,b=0`), two columns (both `d=1`) — `c` drops out, `a`, `b`, `d` stay.
- **`ab=01,11` rows × `cd=11` column → `b & c & d`.** Two rows (both `b=1`), one column (`c=1,d=1`) — `a` drops out, `b`, `c`, `d` stay.

Summed together: `out = (~a & ~d) | (~b & ~c) | (a & ~b & d) | (b & c & d)` — exactly the solution below.

## Approach

The two 2-literal terms (`~a & ~d`, `~b & ~c`) are doing almost all the work — together they cover 8 of the map's 10 ones, leaving only 2 stragglers (`a=1,b=0,c=1,d=1` and `a=1,b=1,c=1,d=1`) for the two 3-literal terms to mop up. Finding those two big terms first is what keeps this expression short; missing them and instead covering the map with several 3- or 4-literal groups (see Gotchas) still produces a functionally correct circuit, just a needlessly larger one.

## Gotchas / things to watch for

- **Missing `~a & ~d` and `~b & ~c` because they only exist as wraparound groups.** This is the main trap in this problem. `~a & ~d`'s two columns are `cd=00` and `cd=10` — the *first* and *last* columns in the Gray-code ordering, not neighbours in the way you'd read left-to-right. They're only adjacent because Gray-code ordering wraps: column `10` sits right next to column `00` when you treat the map as wrapping around its left/right edge, the same way [[Kmap1]] flagged for a 3-variable map. `~b & ~c` has the identical issue on the *other* axis — its two rows are `ab=00` and `ab=10`, the first and last rows, adjacent only via the top/bottom wraparound. If you scan the grid left-to-right, top-to-bottom without remembering the edges wrap, both of these groups are invisible: the four cells that make up `~a & ~d` don't look connected on the page, they just happen to be logically adjacent. Skipping them doesn't produce a wrong circuit — the two straggler cells they'd otherwise help cover can still be picked up by other groups — but the resulting expression ends up considerably longer (more terms, more literals per term) for a circuit that does exactly the same thing. Actively checking each edge for a wraparound match, rather than only grouping what visually looks contiguous, is what catches them.
- **Treating the map as if only orthogonally-adjacent cells count.** Related to the above: a group has to be a rectangle (or square) of 1s whose *side lengths* are powers of two, and "adjacent" always means "differs in exactly one variable" — which includes the wraparound pairs, not just cells that are visually side-by-side in the middle of the grid.
- **Forgetting a variable actually drops out.** `~a & ~d` covers 4 cells (2×2), so 2 of the 4 variables must vanish from the term — it's easy to accidentally leave `b` or `c` in the expression out of caution, but if the group is genuinely valid, both really do vary freely across all 4 cells and neither belongs in the term.
- **Bitwise vs. logical operators again.** As in [[Kmap1]], every operator here needs to be `&`/`|`/`~` (bitwise) not `&&`/`||`/`!` (logical) — they happen to agree on single-bit operands, but writing `&&` here out of habit is the kind of thing that breaks the moment this pattern gets reused on a vector input elsewhere.

## Solution

See `kmap2.v`.
