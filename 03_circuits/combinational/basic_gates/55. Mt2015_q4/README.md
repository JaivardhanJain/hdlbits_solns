# Mt2015_q4

**HDLBits link:** https://hdlbits.01xz.net/wiki/Mt2015_q4
**Category:** Module Hierarchy
**Difficulty:** ⭐⭐

## Problem summary

Instantiate the solutions of q4a and q4b and add logic to get the desired result. 

## Approach

- Paste the solutions of q4a and q4b and instantiate them twice each.
- Add an OR and an AND gate, XOR the result. 

## Gotchas / things I got wrong initially
- Positional port connections are fragile. The solution wires each instance by position — `A ia1 (x, y, o1);` — which only works because the argument order happens to match module A's port list exactly. If A's ports ever get reordered, every instantiation like this silently connects to the wrong signals instead of failing to compile. Named connections (`A ia1 (.x(x), .y(y), .z(o1));`) cost a few extra characters but tie each connection to a port name instead of a position, which is the safer default once a module has more than one or two ports.
- Declaring the intermediate wires (`o1`–`o4`) matters more here than it looks. These are the signals carrying values between instances, so if you forget the `wire` declaration and don't have `default_nettype none` set, Verilog silently creates an implicit 1-bit net for you — same silent-bug risk as the Wire_decl lesson, just showing up at a module boundary instead of inside a single module.
- Generic single-letter module names like `A` and `B` only feel safe because HDLBits compiles each problem in isolation. Module names live in one global namespace per compilation — in a real project pulling files together, a generic name is one accidental match away from colliding with an unrelated module elsewhere in the codebase. Prefer a descriptive, problem-scoped name even for small submodules.

## Solution

See `Mt2015_q4.v`
