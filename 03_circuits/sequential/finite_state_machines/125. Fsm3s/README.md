# Fsm3s

**HDLBits link:** https://hdlbits.01xz.net/wiki/Fsm3s
**Category:** Circuits: Sequential (Finite State Machines)
**Difficulty:** ⭐⭐

## Problem summary

The four-state machine from [[Fsm3]], with the same table, but the reset into `A` is now **synchronous**. `A` stays on 0 and goes to `B` on 1. `B` stays on 1 and goes to `C` on 0. `C` goes to `A` on 0 and `D` on 1. `D` goes to `C` on 0 and `B` on 1. `out` is 1 only in `D`. As in Fsm3, the encoding is up to you.

## Approach

It's binary encoding with a symbolic `case`, the same shape as Fsm3's `alt2.v`, with the reset moved inside the clock edge:

- **Next state:** one `case` branch per table row, each a ternary on `in`.
- **State register:** `always @(posedge clk)` only, so `reset` is sampled on the edge, with `if (reset)` first so that it wins over every transition.
- **Output:** `state == D`.

A trace that asserts `reset` in the middle of a run, from `D`, so you can see it wait for the edge:

| Edge | `reset` | `in` | `state` before | `next_state` | `state` after | `out` after |
|:----:|:-------:|:----:|:--------------:|:------------:|:-------------:|:-----------:|
| 1 | 1 | – | x | – | A (0) | 0 |
| 2 | 0 | 1 | A (0) | B (1) | B (1) | 0 |
| 3 | 0 | 0 | B (1) | C (2) | C (2) | 0 |
| 4 | 0 | 1 | C (2) | D (3) | D (3) | 1 |
| 5 | 1 | 1 | D (3) | B (ignored) | A (0) | 0 |
| 6 | 0 | 1 | A (0) | B (1) | B (1) | 0 |

At edge 5, `next_state` is still computed as `B`, since the combinational logic doesn't know about reset, but the flop block's `if (reset)` overrides it and loads `A`. Between `reset` rising and edge 5, the machine sits in `D` with `out = 1`. With Fsm3's `areset`, it would have dropped to `A` immediately.

## Gotchas / things to watch for

- **`state` is 4 bits wide, but the encoding only uses 2, so the `case` is no longer full and `next_state` becomes a latch.** With `reg [1:0] state`, the four branches `A`–`D` cover every possible value, the warning in [[Fsm1]] never applies, and no `default` is needed. Widen the register to `[3:0]` (most likely carried over from Fsm3's one-hot version, which genuinely needed 4 bits) and `state` can now hold 16 values. Twelve of them, 4 through 15, match no branch. For those, nothing assigns `next_state`, and in an `always @(*)` block that means "keep the old value": a latch, which is exactly the case that [[Fsm1]] and [[Always_nolatches]] warned would appear "the moment the encoding has unused codes". It passes the grader, because reset puts the machine in `A` and it never leaves 0–3, so the latch is never exercised in simulation. Synthesis can't rely on that reachability argument, though: it sees an incomplete `case` and builds the latch, and reports it as a warning that's easy to scroll past. The fix is either `reg [1:0] state, next_state;` (the right width) or a `default: next_state = A;` (catch-all). Both is better.
- **Too wide here, too narrow in [[Fsm3]]'s `alt2.v`: register width has to come from the state count, deliberately.** In `alt2.v` the danger was a fifth state truncating into an existing one. Here it's the reverse: spare codes no branch handles. Both come from writing the width by hand, separately from the parameter list, with nothing checking that the two agree. A SystemVerilog `enum` sizes the register from its members, and a sized `localparam [1:0] A = 2'd0, ...` at least makes a mismatch visible. The extra two flops cost area too. Their inputs are always 0, so synthesis *may* optimize them away, but nothing guarantees it.
- **Resetting to `0` is correct here and was fatal in Fsm3's one-hot version.** In binary encoding `A` *is* 0, so `state <= A` and `state <= 0` give the same circuit. In one-hot, 0 was the lock-up state. The named parameter is right in both, which is the argument for always resetting by name.
- **Sync vs. async: only the sensitivity list changed from Fsm3.** It's the same as the [[Fsm1s]] and [[Fsm2s]] pairs. The `if (reset)` line is identical, and `, posedge areset` is gone. The trace's edge 5 shows the consequence: reset waits for the clock, and the combinational `next_state` still computes as though reset weren't there, because the override lives entirely in the flop block.
- **Unsized parameters compared against a sized register.** `parameter A = 0` is a 32-bit integer, so `state == D` compares 4 bits against 32 after zero-extension. It's correct here, but it's the implicit-resizing theme from Step One. `localparam [1:0]`, once `state` is the right width, keeps both sides the same width.
- **The good part: one dialect, and `==` rather than `===`.** It's plain Verilog-2001 throughout, as in [[Fsm2s]], and the output compare uses `==`, so a pre-reset `x` shows up as `x` (see [[Fsm1]]).

## Solution

See `fsm3s.v`.
