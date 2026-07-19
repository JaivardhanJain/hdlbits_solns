# Mt2015_q4a

**HDLBits link:** https://hdlbits.01xz.net/wiki/Mt2015_q4a
**Category:** Verilog Basics
**Difficulty:** ⭐

## Problem summary

Create a simple circuit with the functionality of the equation given in the question.

## Approach

Just use the continous assign ('assign') and the logic given in the question. 

## Gotchas / things I got wrong initially
- Watch operator precedence between `^` and `&`. In Verilog, `&` binds tighter than `^` (same ordering as C), so `z = x ^ y & x` actually parses as `z = x ^ (y & x)`, not `z = (x ^ y) & x`. It's easy to assume XOR groups more loosely like a lower-priority arithmetic op and drop the parens. For this particular equation the two forms happen to evaluate the same (AND distributes over XOR, so `x&(x^y)` and `x^(x&y)` are equal), but that's a coincidence of this equation, not something to rely on in general — keep the explicit parens matching the spec.

## Solution

See `Mt2015_q4a.v`
