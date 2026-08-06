# Exams/m2014 q3

**HDLBits link:** https://hdlbits.01xz.net/wiki/Exams/m2014_q3
**Category:** Circuits: Combinational (Karnaugh Map to Circuit)
**Difficulty:** ⭐⭐

## Problem summary

Another K-map-to-circuit problem in the spirit of [[Kmap1]]–[[Kmap4]], including don't-care (`d`) cells (see [[Kmap3]] for what those mean). What's different here isn't the logic — it's the interface: instead of four separate scalar inputs `a,b,c,d` like every prior problem in this chapter, the four variables arrive packed into a single 4-bit vector, `input [4:1] x`. Refer to the diagram on the [HDLBits page itself](https://hdlbits.01xz.net/wiki/Exams/m2014_q3) for the map's actual layout of 1s, 0s, and don't-cares.

## Approach

The process is unchanged from [[Kmap1]]–[[Kmap4]]: read the map, group adjacent 1-cells (folding in whichever don't-cares help) into the largest legal rectangles, turn each group into a product term, sum them. What changes is only the last step — instead of writing `assign out = (...)` using separate named signals, every literal in the equation has to reference a bit of the vector: `x[1]`, `x[2]`, `x[3]`, `x[4]` in place of what would elsewhere be `a`, `b`, `c`, `d`. The given solution, `f = (~x[1] & x[3]) + (x[2] & ~x[3] & x[4])`, is two product terms — a 2-literal term requiring `x[1]=0, x[3]=1`, and a 3-literal term requiring `x[2]=1, x[3]=0, x[4]=1` — summed.

## Gotchas / things to watch for

- **`x` is indexed `[4:1]`, not `[3:0]` or `[4:0]`.** There is no `x[0]` — the vector is 4 bits wide (`4 - 1 + 1 = 4`) but numbered starting at 1. It's easy to instinctively reach for `x[0]` out of habit from every zero-indexed vector problem earlier in this repo (Vector0 onward), or to assume a 4-bit vector must span `[3:0]`. Both would either reference a nonexistent bit or silently reference the wrong one.
- **The module declaration's exact range has to be preserved.** Because HDLBits's testbench drives the port by name and width, changing the declaration to, say, `input [3:0] x` (even though it's still "4 bits") and then writing `x[3]` where you meant the map's fourth variable would compile fine but silently swap which physical bit is being read — the range in the port declaration isn't cosmetic, it's what defines which index refers to which wire.
- **Mapping the K-map's variable labels to the correct vector index.** With separate scalar inputs (`a,b,c,d`), there's no ambiguity about which signal is which. With a packed vector, you additionally have to confirm which of `x[1]`–`x[4]` corresponds to which axis of the map (typically whichever variable the diagram itself labels `x1`…`x4`) — mixing up, say, `x[1]` and `x[4]` produces a completely different (but still plausible-looking) function, and there's no compiler error to catch it.
- **Reaching for `+` as if it were `|`.** The given solution combines its two product terms with `+` (arithmetic addition) rather than `|` (bitwise OR). This only works because the two terms can never both be 1 at once — the first requires `x[3]=1`, the second requires `x[3]=0`, so they're mutually exclusive by construction, and `0+1`, `1+0`, `0+0` all agree with what `|` would produce. If two overlapping (not mutually exclusive) 1-bit terms were ever added this way, `1 + 1 = 2` (binary `10`) would get truncated back down to a 1-bit result of `0` — the opposite of the `1` that OR would correctly produce. `|` doesn't have this failure mode at all, since bitwise OR of two 1-bit values is never anything but `0` or `1`. Worth defaulting to `|` for combining boolean terms and reserving `+` for genuine arithmetic, rather than relying on term exclusivity holding by coincidence.

## Solution

See `exams_m2014_q3.v`.
