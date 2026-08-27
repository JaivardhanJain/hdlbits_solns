# Module_name

**HDLBits link:** https://hdlbits.01xz.net/wiki/Module_name
**Category:** Verilog Language: Modules: Hierarchy
**Difficulty:** ⭐

## Problem summary

Same 6-port `mod_a` as [Module_pos](../21.%20Module_pos/README.md), except its ports are now properly named (`out1`, `out2`, `in1`–`in4`) and must be connected *by name*: `in1`→`a`, `in2`→`b`, `in3`→`c`, `in4`→`d`, `out1`→`out1`, `out2`→`out2`.

## Approach

```verilog
mod_a inst1 (
    .in1(a), .in2(b), .in3(c), .in4(d),
    .out1(out1), .out2(out2)
);
```

That's it — the mapping table on the problem page transcribes directly into the connection list, one line each, with no mental bookkeeping in between.

The detail worth pausing on: `mod_a` declares its ports outputs-first, and the solution lists inputs first. That mismatch is not sloppiness and not a bug — **it has no effect whatsoever**. Named connection binds `.in1` to the port called `in1` no matter where that port sits in the declaration, so the instantiation can be written in whatever order reads best. Grouping inputs together and outputs together, as here, is a common house style precisely because it's now free to do.

Compare against Module_pos (21), where the same freedom didn't exist: there the argument order *was* the connection, and writing inputs first would have produced a silently wrong circuit. The three problems in a row make the point cleanly — Module (20) introduced both forms, Module_pos showed what positional costs you, and this one shows what named buys.

## Gotchas / things I got wrong initially

- **`.out1(out1)` is two different signals, not a self-connection.** Left of the parens is `mod_a`'s port; inside is `top_module`'s wire. They share a name here by design of the problem, which makes the line look redundant, but the connection is doing real work — the same scoping point first raised on `.out(out)` in Module (20). The corollary still holds: identical names connect to nothing until you write the connection.

- **A typo'd port name is a compile error, and that's the feature.** `.in5(d)` fails immediately because `mod_a` has no port `in5`. In Module_pos, the equivalent mistake — an argument in the wrong slot — compiled fine and failed in simulation. Named connection converts a silent functional bug into a loud syntax error, which is the entire argument for it in one sentence.

- **Omitting a port is still silent.** Named connection catches *wrong* names, not *missing* ones. Drop `.in4(d)` and it compiles, with `in4` left floating `x`/`z` inside `mod_a`. So the error-catching is real but partial — connect every port, and write `.port()` explicitly if one is deliberately unused.

- **The period is part of the syntax, not decoration.** `in1(a)` without the leading dot doesn't mean "port in1"; the parser reads it as an expression in a positional list, and you get either a confusing error or, worse, an accidentally valid positional connection. Watch for this when hand-editing an instantiation.

- **Still no mixing.** An instantiation is entirely named or entirely positional. Converting Module_pos's version to this one means rewriting all six connections, not four.

- **Named connection does not check direction or width either.** It guarantees you attached the signal you meant to the port you meant — nothing more. Connecting a 4-bit wire to an 8-bit port still zero-extends silently, the same width-mismatch class of bug that runs from Step One onward. Correct names are not the same as a correct interface.

## Solution

See `module_name.v`
