# Norgate

**HDLBits link:** https://hdlbits.01xz.net/wiki/Norgate
**Category:** Verilog Basics
**Difficulty:** ⭐

## Problem summary

Nor the inputs and wire them to the output.


## Approach

A continuous assignment (`assign`) from the inputs to the output, after adding an or ('|') and then inverting that result.

## Gotchas / things I got wrong initially
 - Prefer ~(a | b) over !(a | b). Both work on 1-bit inputs, but ~ is bitwise (correct even if the module later widens to vectors), while ! reduces the whole expression to a single boolean bit — on a vector, that silently produces a 1-bit result zero-extended into a wider output. ~/&/|/^ are for data-path logic; !/&&/|| are for boolean contexts like if conditions.

## Solution

See `nor_gate.v`
