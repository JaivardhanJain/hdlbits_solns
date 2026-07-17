# Exams/m2014 q4i

**HDLBits link:** https://hdlbits.01xz.net/wiki/Exams/m2014_q4i
**Category:** Verilog Basics
**Difficulty:** ⭐

## Problem summary

Simplest possible module: Set an output to low.

## Approach

Just a continuous assignment (`assign`) from 1'b0 to the output, no logic needed.

## Gotchas / things I got wrong initially
- Note that wires are directional, so "assign 1'b0 = out" is not equivalent.

## Solution

See `exams_m2014_q4i.v`
