# Mt2015_q4b

**HDLBits link:** https://hdlbits.01xz.net/wiki/Mt2015_q4b
**Category:** Verilog Basics
**Difficulty:** ⭐⭐

## Problem summary

Create a simple circuit with the functionality to match the waveforms in the image.

## Approach

- Treat the waveform as a truth table and write the sum of products.
- Observe that z is high when the inputs are the same value (XNOR) and use necessary logic.

## Gotchas / things I got wrong initially
- `assign z = (x == y);` also passes here since x and y are single bits, but it's a habit worth breaking early: `==` collapses a multi-bit comparison down to a single 1-bit "are these equal" result, whereas `~^` (or `~(a^b)`) does a per-bit XNOR and returns a vector the same width as the inputs. Reach for `~^`/`^~` for datapath logic like this — same bitwise-vs-logical distinction as Norgate/Andgate/Xnorgate, it just doesn't bite until you hit a vector version of this circuit.

## Solution

See `Mt2015_q4b.v`
