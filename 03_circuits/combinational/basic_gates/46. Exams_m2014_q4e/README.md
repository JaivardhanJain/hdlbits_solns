# Exams/m2014 q4e

**HDLBits link:** https://hdlbits.01xz.net/wiki/Exams/m2014_q4e
**Category:** Verilog Basics
**Difficulty:** ⭐

## Problem summary

Given two inputs, output their NOR. 

## Approach

Just a continuous assignment (`assign`) with NOR logic.

## Gotchas / things I got wrong initially
- Note that both || and | work here, but the bitwise operator is best practice.
- Cannot bring the ~ into the bracket. /A + /B isn't the same as /(A + B) (that is equivalent to /A * /B according to DeMorgan's Theorem)

## Solution

See `exams_m2014_q4e.v`
