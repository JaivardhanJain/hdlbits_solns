# Truthtable1

**HDLBits link:** https://hdlbits.01xz.net/wiki/Truthtable1
**Category:** Truthtable
**Difficulty:** ⭐⭐⭐

## Problem summary

Synthesize the circuit from the truth table.

## Approach

Use Sum-of-Products to find the minterms of the truthtable. Then use K-maps, boolean algebra or observation to simplify the result. 

## Gotchas / things I got wrong initially
- Leaving the unsimplified canonical SOP as the final assigned expression. Writing out one AND term per minterm and ORing them is a correct first step, but it's not the deliverable — HDLBits' own page notes the expected solution is "around 1 line." An unsimplified SOP synthesizes to more gates and a longer critical path than necessary. Derive the full SOP to convince yourself it's correct, then actually assign the minimized expression (via K-map/boolean algebra); keep the full SOP as a comment for reference, not as the live logic.
- Truth-table row/bit-order mix-ups. It's easy to misread which column is MSB vs LSB, or miscount which row number maps to which input combination, when hand-translating a truth table into minterms. A swapped bit order still produces a "valid" boolean circuit — it just implements the wrong function — so it won't error, only fail the testbench. Double-check row number = binary(x3x2x1) before writing minterms, especially as tables grow in later K-map problems.

## Solution

See `truthtable1.v`
