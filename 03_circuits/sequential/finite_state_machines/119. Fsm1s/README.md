# Fsm1s

**HDLBits link:** https://hdlbits.01xz.net/wiki/Fsm1s
**Category:** Circuits: Sequential (Finite State Machines)
**Difficulty:** ⭐⭐

## Problem summary

The same two-state Moore machine as [[Fsm1]] — output 1 in `B`, 0 in `A`, hold on `in = 1`, toggle on `in = 0` — but the reset into `B` is now **synchronous**. The other change is the template HDLBits hands you: a Verilog-1995 header, and the whole FSM (next state, state register, output) packed into a single clocked `always` block. The circuit is identical to Fsm1's apart from the reset; the interesting part is what the single-block style does to the code.

## Approach

Everything that matters happens on the clock edge, so the solution keeps HDLBits's one-block shape for the state logic:

- **Reset first.** `if (reset)` wraps everything else, so reset beats any transition. Because the block is only sensitive to `posedge clk`, reset is sampled on the edge like any other input — that one sensitivity list is the entire difference from Fsm1.
- **Next state as a temporary.** Inside the `else`, the `case` computes `next_state` with a blocking `=`, and the very next statement registers it with `present_state <= next_state`. Because the blocking assignment takes effect immediately, the `<=` picks up *this* cycle's next state, not last cycle's.
- **Output outside the block.** HDLBits's template puts a second `case` for the output inside the clocked block; this solution replaces it with a continuous `assign`, which keeps `out` purely combinational from the state — what a Moore output should be.

A trace, with `reset` and `in` sampled on each rising edge. Edge 4 is the one that differs from Fsm1: reset is asserted while in `A`, and nothing happens until the edge.

| Edge | `reset` | `in` | `present_state` before | `present_state` after | `out` after |
|:----:|:-------:|:----:|:----------------------:|:---------------------:|:-----------:|
| 1 | 1 | – | x | B | 1 |
| 2 | 0 | 1 | B | B | 1 |
| 3 | 0 | 0 | B | A | 0 |
| 4 | 1 | 1 | A | B | 1 |
| 5 | 0 | 0 | B | A | 0 |

Before edge 1 the state is `x` and so is `out`: a synchronous reset can't initialize anything until the clock actually ticks, whereas Fsm1's `areset` forces `B` the instant it rises.

## Gotchas / things to watch for

- **`reg out;` plus `assign out = ...` is illegal Verilog-2001 — and this time it's the template's `reg` that went stale.** HDLBits declares `reg out;` because its template drives `out` from a `case` inside the `always` block, which is a procedural assignment and needs a variable. Swapping that `case` for an `assign` changes the driver to a continuous assignment, which must drive a **net**. It passes only because HDLBits compiles as SystemVerilog. The fix is to delete `reg out;`. This is the same rule as [[Exams_ece241_2013_q12]]: whether a signal is `reg` depends on *how* it's assigned, so changing the assignment style means changing the declaration too. The Verilog-1995 header makes that easy to miss, because the `reg` sits on its own line, away from both the port list and the `assign`.
- **`present_state` gets a blocking `=` in reset and a non-blocking `<=` everywhere else.** In simulation it works, because nothing else reads `present_state` in the same time step. But mixing the two assignment types on one variable is a lint error, and some synthesis tools (Synopsys Design Compiler among them) refuse it outright. The rule from [[Dff]] applies: a flop gets `<=`, every assignment, every branch. Write `present_state <= B;`.
- **HDLBits's own template uses a blocking `present_state = next_state;` — and that's why its in-block output `case` worked.** With `=`, the state updates immediately, so a `case` placed after it in the same block sees the *new* state, and the registered `out` matches it. Change that line to `<=` (which is correct for a flop) and keep the output `case` in the block, and `out` reads the *old* state and lags `present_state` by one cycle. That's a silent off-by-one that a Moore spec will fail. Moving the output to an `assign`, as this solution does, is the clean way out: `<=` for the flop, and an output that is a function of the state rather than a second register.
- **`next_state` is a variable written inside a clocked block, so it's only combinational by luck of ordering.** It's assigned before it's read on every path that reads it, so synthesis turns it into wires. Read it on a path that doesn't assign it first, and you get a flop holding last cycle's value. The single-block style blurs exactly the line that [[Fsm1]]'s three-part template keeps sharp. There, `next_state` lives in its own combinational block and *can't* become state. For anything bigger than two states, use the separate blocks.
- **Sync vs. async reset is decided by the sensitivity list alone.** Put `or posedge reset` in it and this becomes Fsm1. The `if (reset)` body is word-for-word the same in both versions — the same trap as [[Lfsr5]] vs. [[Shift4]]. When you're reviewing someone's FSM, read the sensitivity list before the reset branch.
- **`assign out = present_state;` only works because `B` happens to be 1.** It's the encoding-dependence trap covered in [[Fsm1]]. If the encoding is ever swapped, the output silently inverts. `assign out = (present_state == B);` says what the spec says.
- **Prefer ANSI-style port declarations.** In the Verilog-1995 style, each port is named in the list and then declared again with its direction, so its type and width can end up several lines away. ANSI style (`module top_module(input clk, input reset, input in, output out);`) declares each port once, in one place. That is also where you'd have noticed `out` didn't need to be `reg`. You'll still see 1995-style headers in legacy code, so recognize them, but don't write new ones.
- **No `default` in the `case`** — harmless with a 1-bit state, a latch-in-waiting later; see [[Fsm1]] and [[Always_nolatches]].

## Solution

See `fsm1s.v`.
