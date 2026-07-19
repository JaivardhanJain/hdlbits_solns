# Exams/m2014 q4f

**HDLBits link:** https://hdlbits.01xz.net/wiki/Exams/m2014_q4f
**Category:** Verilog Basics
**Difficulty:** ⭐

## Problem summary

Given two inputs, invert one and AND that result with the other input. 

## Approach

Just a continuous assignment (`assign`) with AND logic (after inverting one of the inputs).

## Gotchas / things I got wrong initially
- Note that both && and & work here, but the bitwise operator is best practice.

## Solution

See `exams_m2014_q4f.v`
