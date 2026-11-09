# Fsm1

**HDLBits link:** https://hdlbits.01xz.net/wiki/Fsm1
**Category:** Circuits: Sequential (Finite State Machines)
**Difficulty:** ⭐⭐

## Problem summary

The first FSM in the series: a Moore machine with two states (`A`, `B`), one input, one output, and an **asynchronous** reset into `B`. In `B` the output is 1; in `A` it's 0. Whenever `in` is 1 the machine stays put, and whenever `in` is 0 it flips to the other state. The circuit itself is trivial — HDLBits points out it's just a T flip-flop with its T input inverted — but the point of the problem is the *shape* of the code, because every FSM after this one is written the same way.

## Approach

The solution uses the standard three-part FSM template, and each part goes in the construct that matches what it is:

1. **Next-state logic** — a pure function of `state` and `in`, so it lives in a combinational block (`always_comb`) with blocking `=`. One `case` branch per state, reading straight off the diagram's arrows.
2. **State register** — the only storage in the design, so it's the only clocked block (`always_ff`), with non-blocking `<=` and the async reset in the sensitivity list.
3. **Output logic** — Moore, so the output depends on `state` alone and is a single continuous `assign`.

Keeping these separate is what makes larger FSMs reviewable: you can check the arrows against the `case`, the reset against the flop block, and the output table against the `assign`, each in isolation.

A trace, starting from reset, with `in` = 1, 0, 1, 0, 0 on successive clock edges:

| Edge | `in` | `state` before | `next_state` | `state` after | `out` after |
|:----:|:----:|:--------------:|:------------:|:-------------:|:-----------:|
| reset | – | x | – | B | 1 |
| 1 | 1 | B | B | B | 1 |
| 2 | 0 | B | A | A | 0 |
| 3 | 1 | A | A | A | 0 |
| 4 | 0 | A | B | B | 1 |
| 5 | 0 | B | A | A | 0 |

`in = 0` toggles, `in = 1` holds — which is exactly the TFF-with-inverted-T description. Note that the reset row needs no clock edge: `areset` rising forces `B` immediately.

## Gotchas / things to watch for

- **`===` is a simulation operator; use `==` in design code.** `===` (case equality) compares `x` and `z` bits *literally* and always returns a clean 0 or 1, which is useful in a testbench and wrong in RTL. Synthesis tools either reject it or quietly treat it as `==`, so the hardware is the same — but the simulation isn't. Before the first reset, `state` is `x` (registers power up undefined, the same theme as [[Rotate100]] and [[Lfsr5]]). With `==`, `out` is `x` too, and the waveform tells you the machine hasn't been initialized. With `===`, `x === 1` is simply 0, so `out` shows a confident, wrong 0 and the uninitialized state is hidden. The solution here passes the grader because the testbench resets first; change it to `state == B` and nothing else moves.
- **`always_comb` / `always_ff` are SystemVerilog, and this is a `.v` file.** They pass because HDLBits compiles as SystemVerilog — the same leniency behind the missing-`reg` headers in [[Lfsr5]] and [[Mt2015_lfsr]]. They're genuinely better than `always @(*)` and `always @(posedge clk ...)`: tools will warn if an `always_comb` infers a latch or an `always_ff` doesn't infer a flop, so the keyword states your intent and gets it checked. But use them in `.sv` files; a strict Verilog-2001 flow will reject them outright. Pick one dialect per file rather than mixing.
- **The `case` has no `default`, and here that's fine — by luck of the encoding.** A 1-bit `state` has exactly two values and both are covered, so every path assigns `next_state` and no latch is inferred. That stops being true the moment the encoding has unused codes (three states in two bits, or one-hot): an uncovered value in a *combinational* block means "keep the old value," which is a latch. That's the opposite of the clocked-block rule from [[Shift4]], where a missing `else` is just "hold." Make `default: next_state = B;` (or assign a default before the `case`) a habit now, before the FSMs get big enough for it to matter — see [[Always_nolatches]].
- **State encodings should be `localparam`, not `parameter`.** HDLBits's template uses `parameter`, which can be overridden from outside: an instantiation with `#(.A(1))` would make `A` and `B` the same code and the FSM would silently stop working. Encodings are internal to the module, so `localparam` is the right keyword. In production SystemVerilog the usual next step is `typedef enum logic {A, B} state_t;`, which also makes the waveform viewer show `A`/`B` instead of `0`/`1`.
- **`assign out = state;` would also pass — and silently invert if anyone re-encodes the states.** Because `B` happens to be 1, the output *is* the state bit. Writing it as `state == B` keeps the output tied to the state's *name*, so swapping the encoding (or moving to one-hot) can't break it. The general rule: let the code say which states produce which outputs, and let the encoding be an implementation detail.
- **The reset state is `B`, i.e. 1 — the reset doesn't have to be 0.** `areset` drives the flop to 1, so it maps to a flop with an async *preset* rather than a clear. Nothing about this is unusual, but it's easy to write `state <= 0` out of habit and get `A`. Same async-reset template as [[Dff8ar]] and [[Shift4]], with the same production caveat: assert asynchronously, de-assert through a synchronizer.
- **Yes, this can be written without an FSM — but don't, yet.** `state <= state ^ ~in;` is the whole next-state function, and it's correct. But it hides the diagram: there's no line you can check against an arrow. The template version costs a few lines and scales to every FSM in the rest of this chapter; the clever version doesn't scale to any of them.

## Solution

See `fsm1.v`.
