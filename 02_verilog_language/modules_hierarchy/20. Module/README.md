# Module

**HDLBits link:** https://hdlbits.01xz.net/wiki/Module
**Category:** Verilog Language: Modules: Hierarchy
**Difficulty:** ⭐

## Problem summary

A sub-module `mod_a` is given with ports `in1`, `in2`, `out`. Create one instance of it inside `top_module` and wire its three pins to `top_module`'s `a`, `b`, and `out`. No logic of our own — this is purely about hierarchy.

## Approach

Everything up to this point has been written *inside* one module. This is the first problem where a design is built by *composing* modules: `top_module` contains an instance of `mod_a`, and the two are siblings in the source file, never nested.

### Instantiation syntax

An instantiation is three parts:

```verilog
mod_a   inst1   ( ...port connections... );
//  ^      ^
//  |      +-- instance name (unique within the enclosing module)
//  +--------- module type (name of the module being instantiated)
```

The module type is like a class; the instance name is like a variable. Instantiate `mod_a` ten times and you get ten separate copies of the hardware, each needing its own instance name (`inst1`, `inst2`, …). This is not a function call — nothing is "invoked". The line means *a physical copy of this circuit exists here*, permanently, whether or not anything ever changes on its inputs.

Ports can be connected two ways.

**By position** — arguments are matched left-to-right against the sub-module's declared port order, C-style:

```verilog
mod_a inst2 ( a, b, out );   // a -> in1, b -> in2, out -> out
```

**By name** — each connection names the port explicitly, with a leading period:

```verilog
mod_a inst1 ( .in1(a), .in2(b), .out(out) );
```

Inside the parentheses, `.in1` is the sub-module's port; `(a)` is the signal in *this* module being attached to it. Order is irrelevant — `.out(out), .in1(a), .in2(b)` is the same circuit.

Both pass the grader. `top_module` here uses by-name, and `alt1` shows the by-position version, because named connection is what real projects use — see the gotchas for why.

## Gotchas / things I got wrong initially

- **Don't nest the sub-module inside `top_module`.** Verilog has no nested module definitions; `endmodule` closes a definition completely. A sub-module's *definition* lives beside `top_module` in the file (or in another file in the same project), and only its *instance* appears inside. In this problem `mod_a`'s body is supplied by HDLBits, so we don't write it at all — same convention already used for the provided black boxes in Bcdadd4 and Exams_ece241_2014_q7a: quote the declaration in a comment, instantiate, move on.

- **Positional connection is a maintenance trap, not a style preference.** If someone later reorders `mod_a`'s ports, or inserts a new one, every positional instantiation silently rewires to the wrong signals. Nothing errors as long as the count still matches — and it usually does. Named connection survives reordering and insertion, which is why essentially every industrial coding standard mandates it. Positional is tolerable only for tiny, frozen primitives (a two-input gate wrapper), and even then it buys very little.

- **A name collision between the parent's wire and the child's port is not a connection.** Here both `mod_a` and `top_module` have a port called `out`, and `.out(out)` looks self-referential. It isn't: the left `out` is `mod_a`'s port, the right `out` is `top_module`'s wire, and they live in different scopes. Sharing a name is coincidence with no semantic effect. The corollary is the more dangerous half — if the names *match*, they're still not connected until you write the connection.

- **Leaving a port off the list connects it to nothing.** `mod_a inst1 ( .in1(a), .in2(b) );` compiles. `out` is simply left unconnected, and the output floats `z` / reads `x` downstream. Simulators usually warn, but a warning in a thousand-line build gets lost. Connect every port, and if one is genuinely unused, write `.out()` explicitly so the intent is on the page.

- **Positional connection cannot skip.** With named ports you can omit or leave one empty; positionally, `mod_a inst2 ( a, , out );` is how you'd have to express it, which is easy to misread and easy to typo into a shifted port list. Another reason the named form is the default.

- **Every instance needs its own name.** Reusing an instance name for two instances of the same module is a compile error, not a silent merge. The instance name is also what shows up in simulator hierarchy paths (`top_module.inst1.out`) and in synthesis reports, so pick something descriptive rather than `u0`/`u1` once designs get bigger — future-you reading a waveform will care.

- **No semicolon inside, one at the end.** The port connections are separated by commas and the whole statement is terminated by `;` after the closing paren. Trailing comma before `)` is a syntax error, and it's the single most common typo when adding a port to an existing instance.

## Solution

See `module.v`
