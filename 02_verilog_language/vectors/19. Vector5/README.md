# Vector5

**HDLBits link:** https://hdlbits.01xz.net/wiki/Vector5
**Category:** Verilog Vectors
**Difficulty:** ⭐⭐

## Problem summary

Given 5 inputs, do all combinations of pairwise comparisons and output in the 25-bit output vector.


## Approach

Input a must be compared to (abcde), so should b and so on. So use the replication operator to replication each input 5 times and replicate the pattern of abcde 5 times. To compare use XNOR because the question asks to have an output of 1 if the value of both bits match.

## Gotchas / things I got wrong initially
 - Bitwise `~` vs. logical `!` matters again here, same trap as Norgate/Andgate but easier to fall into once operands are vectors: `~top` complements all 25 bits, while `!top` would reduce `top` to a single boolean bit first and then get width-extended back — it compiles, but gives the wrong answer.
 - The two vectors need opposite replication strategies: one repeats each input as a block of 5 (`{5{a}}, {5{b}}, ...`), the other repeats the whole 5-input pattern 5 times (`{5{a,b,c,d,e}}`). Swapping which input gets which treatment produces a vector that's just wrong, not merely transposed, since a block-replication and a pattern-replication of the same signals aren't the same thing.
 - `{5{a,b,c,d,e}}` and `{5{a}}` look structurally inconsistent (one brace-pair vs. two visually) but follow the same rule from Vector4: `{count{X}}` requires `X` to already be a valid concatenation. `a,b,c,d,e` is already one, so it doesn't need extra braces; a lone signal like `a` technically does too, it's just that Verilog's syntax lets the single-item case look like it's "missing" a pair. Worth tracing through rather than pattern-matching on brace count.

## Solution

See `vector5.v`
