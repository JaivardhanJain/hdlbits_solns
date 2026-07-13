# Wire decl

**HDLBits link:** https://hdlbits.01xz.net/wiki/Wire_decl
**Category:** Verilog Basics
**Difficulty:** ⭐

## Problem summary

Declare wires and use logic to create the circuit shown in the diagram.


## Approach

Wire the inputs to declared wires through logic and then run those declared wires (which were the results of some logic) thorugh further logic.

## Gotchas / things I got wrong initially
 - `` `default_nettype none `` disables implicit wire creation. Normally Verilog silently creates a 1-bit wire the first time it sees an undeclared identifier, so a typo'd signal name doesn't error — it just creates a dangling, undriven wire and the bug only surfaces as a simulation mismatch. With `default_nettype none`, every net must be explicitly declared, turning that typo into a compile error. Standard practice at the top of real RTL files.
 - Order of `assign` statements doesn't matter. They describe concurrent structural connections, not sequential steps, so reordering them never changes the circuit — unlike software, where line order matters.
 - No need to declare a separate wire if an output port already holds the value you want. `out_n` reuses `out` directly instead of declaring a redundant third wire for it.

## Solution

See `wire_decl.v`
