# Kmap1

**HDLBits link:** https://hdlbits.01xz.net/wiki/Kmap1
**Category:** Circuits: Combinational (Karnaugh Map to Circuit)
**Difficulty:** ⭐⭐

## Problem summary

You're given a 3-variable Karnaugh map (inputs `a`, `b`, `c`) and asked to implement the circuit it describes. HDLBits doesn't check that your expression is *minimal* — only that it's logically equivalent to the map — but the problem explicitly nudges you to simplify by hand first, in both sum-of-products (SOP) and product-of-sums (POS) form, before writing any Verilog.

## What a Karnaugh map actually is

A truth table lists every input combination as a separate row, which makes it easy to build but hard to *simplify by eye* — adjacent rows in the table aren't necessarily adjacent in the boolean sense. A Karnaugh map (K-map) is the same truth table redrawn as a grid, where the rows and columns are ordered in **Gray code** (each adjacent cell differs by exactly one bit) instead of binary counting order. That single change is the whole point: any two cells that are physically next to each other in the grid (including wrapping around the edges) differ in exactly one input variable, so a group of adjacent 1s in the map corresponds directly to a term where that differing variable has dropped out.

For 3 variables, the standard layout puts one variable (here, `a`) on the rows and the other two (`b`, `c`) on the columns, with the columns ordered `00, 01, 11, 10` — Gray code, not `00, 01, 10, 11` — so that column 3 (`10`) is adjacent to column 0 (`00`) when you wrap around.

## How to read one

Each cell in the map holds the output value for one specific input combination (one minterm). To simplify:

- Circle groups of adjacent 1-cells whose size is a power of 2 (1, 2, 4, 8, ...). A group of size 2^n lets you drop n variables from that term — the variables that stay constant across the whole group are the ones that survive in the product term; the ones that change are the ones that cancel out.
- Groups can wrap around the top/bottom and left/right edges of the map, because Gray code ordering means the first and last row/column are also only one bit apart.
- Cover every 1 with at least one group, using the fewest and largest groups possible (each group becomes one product term ORed with the others — fewer, bigger groups means fewer, shorter terms). This gives you the minimal SOP form.
- The dual process — grouping 0-cells instead, then complementing — gives you the minimal POS form. Every K-map has both an SOP and a POS reading; they're always logically equivalent, but one is often more compact than the other depending on how the 1s and 0s happen to cluster.

## Applying it to this problem

Kmap1's map has exactly one 0 in it — the cell where `a = 0, b = 0, c = 0` — and every other cell (all 7 remaining combinations) is a 1.

**SOP reading:** with only one 0 surrounded by 1s everywhere else, no single group can absorb more than 4 of those 1-cells (half the map) without also touching the 0. That gives three separate size-4 groups — one for `a=1` (covering all 4 cells where `a` is 1, regardless of `b`/`c`), one for `b=1`, and one for `c=1` — and between them they cover all 7 ones (with overlap, which is fine; a cell can belong to more than one group). Each group drops the two variables that vary across it and keeps only the one that's constant, so the three prime implicants are simply `a`, `b`, and `c`, summed: `out = a + b + c`.

**POS reading:** grouping the 0s instead, there's only one 0-cell to group — the point `a=0, b=0, c=0` itself — which is its own group of size 1 (no variable drops out). That cell's own term is `a'b'c'`; complementing it via De Morgan's gives the single POS term `(a + b + c)`.

Both readings land on the same expression here, which is what the comments in the solution below are pointing at — it isn't a coincidence specific to how you group things, it's because the map only has one 0, so the "sum of the three single-variable SOP terms" and the "single three-literal POS term" both reduce algebraically to the same OR of three literals.

## Approach

Because both simplification paths converge on the identical boolean expression, there's only one Verilog line to write — no need for separate SOP/POS modules the way some problems in this repo keep multiple valid structural approaches side by side (see [[Bcdadd4]]'s named-vs-generate instantiation, for contrast, where the alternatives really do produce different code). Here `assign out = a | b | c;` is not "one of two valid ways to do it" — it's the single simplified form both ways of reading the map arrive at.

## Gotchas / things to watch for

- **Writing out the un-simplified SOP directly from the map instead of grouping first.** It's tempting to read off all 7 minterms where `out=1` and OR together 7 separate 3-literal AND terms (`a'b'c + a'bc' + a'bc + ...`). That's logically correct — HDLBits only checks equivalence — but it defeats the purpose of the exercise, produces a much larger gate count if this were ever actually synthesized, and is exactly the "didn't simplify the k-map first" mistake the problem statement is warning against.
- **Confusing bitwise OR (`|`) with logical OR (`||`) here.** `a`, `b`, `c` are single-bit signals, so `a | b | c` and `a || b || c` happen to produce the same result for this problem — but they don't mean the same thing in general, and mixing them up on wider signals is a real bug (established back in Norgate/Andgate: `|` is bitwise, `||` is logical, and the SOP/POS reasoning above is fundamentally about bitwise combination of individual signals, not boolean-valued expressions).
- **Assuming the column ordering in a K-map is binary counting order.** If you build the grid with columns `00, 01, 10, 11` (plain binary) instead of `00, 01, 11, 10` (Gray code), adjacent columns won't actually differ by one bit, and grouping "adjacent" cells will silently give you an incorrect simplification. This is the one detail that makes a K-map different from a plain truth table, so it's worth double-checking the axis order before grouping anything.
- **Forgetting that groups can wrap around the map's edges.** With only one 0 in this map, the size-4 group for `c=1`, for example, spans columns `01` and `11` — and depending on how you've drawn the grid, easy to miss that the wrap-around adjacency (`10` next to `00`) is just as valid as any adjacency in the middle of the map.

## Solution

See `kmap1.v`.
