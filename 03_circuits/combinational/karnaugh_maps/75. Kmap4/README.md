# Kmap4

**HDLBits link:** https://hdlbits.01xz.net/wiki/Kmap4
**Category:** Circuits: Combinational (Karnaugh Map to Circuit)
**Difficulty:** ⭐⭐⭐

## Problem summary

A fourth 4-variable K-map (`a`, `b`, `c`, `d`). Same instructions as [[Kmap1]], [[Kmap2]], and [[Kmap3]] — simplify before coding — but the hint on this one is a warning rather than encouragement: *"changing the value of any one input always inverts the output... a simple logic function, but one that can't be easily expressed as SOP nor POS forms."* Refer to the diagram on the [HDLBits page itself](https://hdlbits.01xz.net/wiki/Kmap4) for the map's actual layout.

## Why grouping breaks down here

Every K-map simplification technique used in [[Kmap1]] through [[Kmap3]] depends on one thing: adjacent cells (cells one bit apart) sometimes share the same value, so you can circle a rectangle of same-valued cells and cancel out whichever variables changed across it. This map has the opposite property. The hint says flipping *any single* input always flips the output — which means every cell's four immediate neighbors (one Hamming-distance-1 flip away in each of the 4 variables) all hold the *opposite* value from that cell. There is no pair of adjacent 1s anywhere on the map, and no pair of adjacent 0s either. It's a perfect checkerboard.

That means every "group" you could legally draw has size 1 — a single cell, no variables cancelled. Minimal SOP here isn't a handful of short terms; it's one full 4-literal AND term per 1-cell, OR'd together. A 4-variable function has 16 cells, and this one is exactly half 1s (any function where flipping one bit always flips the output has to be 50/50 — flip any input from a 1-cell and you land on a 0-cell, so 1s and 0s pair off exactly). That's 8 minterms, each a 4-literal product, sum: an 8-term, 32-literal expression. POS is the mirror image — 8 sum terms of 4 literals each, covering the 0-cells. Both are already "fully simplified" in the K-map sense (no term can be shortened further, because there's no adjacency to exploit) and both are still enormous compared to what's actually needed.

## Recognizing the actual pattern

The hint is really describing a named function: this is **parity** (also called an XOR/odd function). Re-reading it in those terms — *"if one or three inputs are 1, output is 1; if zero, two or four are 1, output is 0"* — the rule is: output is 1 exactly when an **odd number** of inputs are 1. That's the definition of a 4-input XOR: `a ^ b ^ c ^ d` is 1 whenever the parity (count of 1-bits) among `a,b,c,d` is odd, and 0 whenever it's even (including all-zero). It's also consistent with the hint's "flip any one input, output flips" property directly: changing one input's value always changes the count of 1s by exactly ±1, which always flips whether that count is odd or even.

So the way to reach the solution isn't K-map grouping at all — it's recognizing that a checkerboard 1/0 pattern where single-bit flips always toggle the output is the signature of parity, and writing the one XOR expression that implements it, rather than grinding through 8 ungroupable minterms.

## Approach

`assign out = a ^ b ^ c ^ d;` is the entire circuit — a chain of three 2-input XOR gates in the synthesized hardware, versus the 8-term SOP or 8-term POS the K-map would otherwise demand. The lesson generalizes beyond this one problem: when a K-map comes back checkerboarded (no legal group bigger than size 1), that's usually a sign the function is better recognized as a named operation — parity/XOR being the classic example — than brute-force simplified cell by cell.

## Gotchas / things to watch for

- **Trying to force K-map grouping to work anyway.** If you don't notice the checkerboard pattern and instead mechanically write out every 1-cell as its own 4-literal product term (as [[Kmap1]]–[[Kmap3]] trained you to do for the *last* group left over), you'll get a working but enormous expression — 8 terms, 32 literals. It'll pass HDLBits's equivalence check, but it defeats the purpose of the exercise, which is explicitly flagging that this map is the case where grouping doesn't help.
- **Missing the parity pattern because it's phrased as "odd number of 1s" rather than "XOR."** The two are the same thing, but if you're scanning for a familiar shape and only have "AND/OR groupings" in mind, the parity function doesn't look like anything from [[Kmap1]]–[[Kmap3]]. It's worth keeping "checkerboard K-map ⇒ probably parity" as a pattern to recognize on sight, the same way a diagonal band of 1s in a 2-variable map is instantly recognizable as XOR/XNOR.
- **Assuming `^` behaves like `|` or `&` here in terms of associativity intuition.** `a ^ b ^ c ^ d` evaluates left-to-right (or in any order — XOR is associative and commutative) and the parity interpretation holds no matter how you group the chain; there's no equivalent of the wraparound-adjacency subtlety from [[Kmap2]] to worry about here, since this isn't derived from grouping cells at all.
- **Reaching for `^^` (logical XOR, not a real Verilog operator) or confusing this with `!=`.** `^` is the bitwise XOR and the correct operator for combining single-bit signals here — same bitwise-vs-logical distinction flagged since Norgate/Andgate, just with `^` instead of `&`/`|`.

## Solution

See `kmap4.v`.
