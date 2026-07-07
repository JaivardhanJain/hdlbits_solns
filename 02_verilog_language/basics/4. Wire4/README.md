# Wire4

**HDLBits link:** https://hdlbits.01xz.net/wiki/Wire4
**Category:** Verilog Basics
**Difficulty:** ⭐

## Problem summary

Wire 3 inputs to 4 outputs according to the diagram on the link.


## Approach

Just a continuous assignment (`assign`) from the inputs to their respective outputs, no logic needed.

## Gotchas / things I got wrong initially
- Note that wires are directional, so "assign in = out" is not equivalent.
- If we're certain about the width of each signal, using the concatenation operator is equivalent and shorter: assign {w,x,y,z} = {a,b,b,c};


## Solution

See `wire4.v`
