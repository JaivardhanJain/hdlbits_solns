# Exams/2012 q1g

**HDLBits link:** https://hdlbits.01xz.net/wiki/Exams/2012_q1g
**Category:** Circuits: Combinational (Karnaugh Map to Circuit)
**Difficulty:** ⭐⭐⭐

## Problem summary

Regular K-map-to-circuit problem similar to the others, and — like [[Exams_m2014_q3]] — with the four variables arriving packed into a single 4-bit vector (`input [4:1] x`) instead of four separate scalar inputs. Refer to the diagram on the [HDLBits page itself](https://hdlbits.01xz.net/wiki/Exams/2012_q1g) for the map's actual layout of 1s and 0s.

## Approach

The process is unchanged from [[Kmap1]]–[[Kmap4]]: read the map, group adjacent 1-cells into the largest legal rectangles, turn each group into a product term, sum them. What changes is only the last step — instead of writing `assign out = (...)` using separate named signals, every literal in the equation has to reference a bit of the vector: `x[1]`, `x[2]`, `x[3]`, `x[4]` in place of what would elsewhere be `a`, `b`, `c`, `d`. The solution below sums three groups: `~x[1] & x[3]` (a 2-literal term — a size-4 group where `x[1]=0, x[3]=1`), `x[2] & x[3] & x[4]` (a 3-literal term, a size-2 group), and `~x[2] & ~x[4]` (another 2-literal, size-4 group) — the same "biggest groups first" reasoning from [[Kmap1]] applies regardless of whether the literals are named `a,b,c,d` or `x[1..4]`.

## Gotchas / things to watch for

- **`x` is indexed `[4:1]`, not `[3:0]` or `[4:0]`.** There is no `x[0]` — the vector is 4 bits wide (`4 - 1 + 1 = 4`) but numbered starting at 1. It's easy to instinctively reach for `x[0]` out of habit from every zero-indexed vector problem earlier in this repo (Vector0 onward), or to assume a 4-bit vector must span `[3:0]`. Both would either reference a nonexistent bit or silently reference the wrong one.
- **Mapping the K-map's variable labels to the correct vector index.** With separate scalar inputs (`a,b,c,d`), there's no ambiguity about which signal is which. With a packed vector, you additionally have to confirm which of `x[1]`–`x[4]` corresponds to which axis of the map (typically whichever variable the diagram itself labels `x1`…`x4`) — mixing up, say, `x[1]` and `x[4]` produces a completely different (but still plausible-looking) function, and there's no compiler error to catch it.
- **Not noticing the corners make a minterm of 4 numbers.** This is easy to miss, which can make the 'assign' very convoluted, which leads to inefficiency and can possibly lead to mistakes as well. The 4 corners are considered to be adjacent because of the wrap around. This means the top-left is adjacent to the top-right and bottom-left and diagonal to the bottom-right, just like any other 4-minterm.

## Solution

See `exams_2012_q1g.v`.
