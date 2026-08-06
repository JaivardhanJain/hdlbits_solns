# Kmap3

**HDLBits link:** https://hdlbits.01xz.net/wiki/Kmap3
**Category:** Circuits: Combinational (Karnaugh Map to Circuit)
**Difficulty:** ⭐⭐

## Problem summary

Another 4-variable K-map (`a`, `b`, `c`, `d`), same task as [[Kmap1]] and [[Kmap2]] — implement the circuit it describes, simplifying by hand first. What's different about this map is that it isn't fully specified with only 0s and 1s: some cells are marked `x` (don't care), and reading those correctly is the whole point of this problem. Refer to the diagram on the [HDLBits page itself](https://hdlbits.01xz.net/wiki/Kmap3) for the actual layout of 1s, 0s, and `x`s — it's an image, not reproduced here.

## What a don't-care cell is

A truth table (and by extension a K-map) doesn't always have to pin down an output for every input combination. A cell is marked `x` — "don't care" — when either the input combination is guaranteed never to occur in the system this circuit sits inside (some upstream encoding rules it out), or when it can occur but nothing downstream depends on what `out` does in that case. Either way, the designer is telling you: "make this cell whatever's most convenient — I'm not going to check it."

That freedom is a simplification tool, not just a shrug. When you're grouping 1-cells into the largest possible power-of-two rectangles (per [[Kmap1]]'s grouping rules), an `x` cell can be pulled into a group as if it were a 1 whenever doing so makes the group bigger — bigger groups mean more variables cancel out, which means shorter terms. You're never obligated to treat every `x` the same way; you can call one `x` a 1 (because it completes a group you want) and a different `x` a 0 (because including it wouldn't help, or would break a group's rectangular shape) in the very same map. HDLBits's grader accounts for this — for any input pattern that was marked `x`, it doesn't check your output at all, so there's no way to get those specific combinations "wrong."

## Applying it here

The solution below reduces to just two terms: `a` (a size-8 group — half the entire cube) and `~b & c` (a size-4 group). Between them they force `out = 1` on exactly 10 of the 16 possible input combinations — every cell with `a=1`, plus the two cells where `a=0, b=0, c=1`. The remaining 6 cells (`a=0`, and not both `b=0` and `c=1`) are left at `out = 0` by this expression. A K-map with no don't-cares at all, needing this few, this large groups, covering exactly this pattern would be a fairly specific coincidence — the more likely explanation for why the map simplifies this cleanly is that some of those remaining 6 cells are actually marked `x` in the original map, and this solution simply resolved each of them to `0` because doing so let the `a` and `~b & c` groups stay as large, rectangular, and few in number as possible. That's the payoff of a don't-care: it turns "I need to draw a group around this awkward leftover 1" into "I can just declare this cell part of whichever neighboring group is already the biggest."

## Approach

With don't-cares in the picture, the simplification process gains one more decision per `x` cell: include it in a group (treat as 1) or leave it out (treat as 0). The heuristic stays the same as always — pick whichever treatment produces the largest, fewest groups — but now that choice is explicitly available on the `x` cells and only implicitly available (by choosing not to group a 1, which you'd never want to do) on the fixed cells. Working from the largest possible group outward (start with "can `a` alone cover half the map?" before considering smaller, more specific terms) is what leads here to `a`, then `~b & c` mopping up the rest.

## Gotchas / things to watch for

- **Treating every don't-care the same way, or forgetting they exist at all.** It's easy to read `x` as "probably a 0, to be safe" and effectively throw the simplification opportunity away, ending up with a longer, more literal-heavy expression than necessary. The whole reason `x` cells are marked instead of just being 0 is that the problem is handing you extra freedom — using it is the intended solution path, not an optional trick.
- **Assuming a don't-care can be resolved independently in every group it touches.** Once you fix what a specific `x` cell evaluates to in your chosen expression (by including or excluding it from a group), that's its value everywhere in that same expression — it can't be a 1 for the purposes of the `a` group and simultaneously a 0 for the purposes of a different group in the same solution. (Different *candidate solutions* can resolve the same don't-care differently — that's fine, and is why more than one equally-valid minimal expression can exist for the same map.)
- **Expecting HDLBits to check your output against the "real" value of a don't-care input.** There isn't one — that's the definition of don't-care. Don't spend time reverse-engineering what the "correct" output for an `x` cell should be; any value your simplification implies for it is equally correct.
- **Bitwise vs. logical operators, again.** Consistent with [[Kmap1]] and [[Kmap2]], `~` and `&` here are the bitwise operators appropriate for combining single-bit signals — not `!`/`&&`.

## Solution

See `kmap3.v`.
