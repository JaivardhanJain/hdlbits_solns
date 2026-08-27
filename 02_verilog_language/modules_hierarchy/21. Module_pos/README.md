# Module_pos

**HDLBits link:** https://hdlbits.01xz.net/wiki/Module_pos
**Category:** Verilog Language: Modules: Hierarchy
**Difficulty:** ⭐⭐

## Problem summary

Same shape as [Module](../20.%20Module/README.md), but `mod_a` now has 6 ports — 2 outputs then 4 inputs, in that order — and they must be connected *by position* to `out1`, `out2`, `a`, `b`, `c`, `d`.

## Approach

One instantiation, arguments listed in the sub-module's declaration order:

```verilog
mod_a inst1 ( out1, out2, a, b, c, d );
```

The only work is getting the order right, and the trap is that `top_module`'s own port list is declared inputs-first (`a, b, c, d, out1, out2`) while `mod_a`'s is outputs-first. Copying `top_module`'s ordering into the instantiation compiles cleanly and is completely wrong — it drives `a` and `b` from `mod_a`'s outputs and feeds `out1`/`out2` in as inputs. Read the order off `mod_a`'s declaration, not off the module you happen to be sitting in.

### Why by-position is right here and wrong almost everywhere else

Module (20) argued that named connection is the professional default. Nothing about that changes — this problem is the exception that shows *why* the rule exists.

Look at the declaration HDLBits gives us:

```verilog
module mod_a ( output, output, input, input, input, input );
```

The ports have directions and nothing else. They are anonymous. `.in1(a)` needs a port called `in1` to attach to, and there isn't one — there is no name to write after the period. Positional connection isn't the stylistic choice here, it's the only mechanism the language leaves available once names are absent.

That's the whole argument for named connection, stated in reverse. Positional connection binds to *ordinal position*, which is an accident of how someone typed the port list; named connection binds to *identity*, which is what you actually meant. When a design is under active development and ports get added, removed, or grouped, position changes and identity doesn't. A positional instantiation quietly follows the port list wherever it moves; a named one stays attached to the signal you named, and errors loudly if that port stops existing.

Real anonymous port lists are vanishingly rare — this declaration is a teaching device. In practice, treat "I have to connect positionally" as a signal that the sub-module's interface is under-specified and worth fixing rather than working around.

## Gotchas / things I got wrong initially

- **The two port lists are ordered differently on purpose.** `top_module` is inputs-then-outputs; `mod_a` is outputs-then-inputs. Writing `mod_a inst1 (a, b, c, d, out1, out2);` — mirroring the module you're writing inside — is the intended trap. Six connections, six ports, no error, wrong circuit. Positional connection has no direction checking to save you here: connecting a `wire` to an output port and vice versa is legal Verilog.

- **The wrong version fails at simulation, not compile.** Because port count still matches and the types are all 1-bit, nothing complains. `out1`/`out2` end up driven by nothing and read as `x`/`z`, and the first sign of trouble is a waveform full of red. This is exactly the "silently rewires" failure mode described in Module (20), and it's worth deliberately noticing that the tools gave you no help at all.

- **Direction is not inferable from the connection.** Beginners often assume Verilog figures out which signals are inputs from context. It doesn't — direction lives entirely in the sub-module's declaration, and the instantiation just attaches nets to ports. `mod_a`'s first two ports are outputs *because `mod_a` says so*, and that's the only reason.

- **Off-by-one drift is the practical hazard.** With six same-width ports, dropping or duplicating one argument shifts every later connection by one slot. If the count happens to still match — say you accidentally wrote `c` twice and omitted `d` — it compiles. Counting arguments against the declaration is a real review step, not paranoia, which is why the solution file keeps a small alignment comment above the instantiation.

- **Don't mix named and positional in one instantiation.** Verilog forbids it: an instantiation is either fully positional or fully named. Half-converting an instance while refactoring is a compile error, which is one of the few places the language is helpfully strict.

- **`mod_a`'s body still isn't ours to write.** Same black-box convention as Module (20), Bcdadd4, and Exams_ece241_2014_q7a — quote the declaration in a comment, instantiate, don't define.

## Solution

See `module_pos.v`
