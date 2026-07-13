# 7458

**HDLBits link:** https://hdlbits.01xz.net/wiki/7458
**Category:** Verilog Basics
**Difficulty:** ⭐⭐

## Problem summary

Declare intermediate wires and/or use continuous assigns to emulate the logic of a 7458 chip (diagram given on the website).


## Approach

`7458.v` contains all three viable approaches as separate modules, so they can be compared side by side:

- **`top_module`** (submitted/graded solution): intermediate wires for each AND gate's output, `assign`ed into the OR gates. Most readable/debuggable of the three — named signals show up individually in waveform viewers.
- **`alt1`**: direct nested `assign`, no intermediate wires. Fine for short expressions like this one, but harder to read/debug as expressions grow.
- **`alt2`**: gate-level primitives (structural modelling). Legacy/pedagogical style — real RTL describes behavior and lets the synthesis tool pick gates.

## Gotchas / things I got wrong initially
 - Only one module in a file submitted to HDLBits can be named `top_module` — that's the specific name its testbench instantiates. Since `alt1`/`alt2` live in the same file for comparison, only `top_module` is actually graded; the others are for reference only and won't be picked up by the grader.
 - `and()`/`or()` are gate primitives, not operators: `and(out, in1, in2, ...)` — output always comes first, followed by any number of inputs. They can only be instantiated at module level (never inside `always`), and each instance drives exactly one output net — they can't be nested inline like an expression.
 - Of the three approaches, intermediate-wire + `assign` is the industry-standard style for real RTL: it documents structure and keeps intermediate values visible in simulation. A single nested `assign` is acceptable for short expressions but doesn't scale. Gate-primitive instantiation locks in an implementation instead of describing behavior — real designs let the synthesis tool pick gates, so `and()`/`or()` are mostly seen in structural netlists or teaching, not hand-written RTL.

## Solution

See `7458.v`
