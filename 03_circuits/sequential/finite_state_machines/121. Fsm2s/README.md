# Fsm2s

**HDLBits link:** https://hdlbits.01xz.net/wiki/Fsm2s
**Category:** Circuits: Sequential (Finite State Machines)
**Difficulty:** ⭐⭐

## Problem summary

The JK flip-flop FSM from [[Fsm2]] again, with the same two states, transitions and output, but the reset into `OFF` is now **synchronous**. `OFF` outputs 0 and leaves for `ON` when `j` is 1. `ON` outputs 1 and goes back to `OFF` when `k` is 1. Otherwise the machine holds.

## Approach

It's the same three-part template as [[Fsm1]] and [[Fsm2]], and the next-state `case` is copied unchanged from Fsm2, because the transitions didn't change. There are two differences:

- **The reset.** The flop block is sensitive to `posedge clk` only, so `reset` is just another input sampled on the edge. The `if (reset)` body is word-for-word what it was in Fsm2. Only the sensitivity list changed.
- **One dialect throughout.** Both blocks are plain Verilog-2001: `always @(*)` for the next state and `always @(posedge clk)` for the flop. That fixes the dialect mix flagged in Fsm2.

A trace that asserts `reset` in the middle of a run, so the synchronous behaviour is visible:

| Edge | `reset` | `j` | `k` | `state` before | `state` after | `out` after |
|:----:|:-------:|:---:|:---:|:--------------:|:-------------:|:-----------:|
| 1 | 1 | – | – | x | OFF | 0 |
| 2 | 0 | 1 | 0 | OFF | ON | 1 |
| 3 | 0 | 0 | 0 | ON | ON | 1 |
| 4 | 1 | 1 | 1 | ON | OFF | 0 |
| 5 | 0 | 1 | 1 | OFF | ON | 1 |
| 6 | 0 | 1 | 1 | ON | OFF | 0 |

At edge 4, `j = k = 1` would normally toggle `ON` to `OFF`, and reset *also* sends it to `OFF`, so the result alone can't show which one won. The structure of the code settles it: `if (reset)` comes first, so reset wins over every transition. Between rising `reset` and edge 4, the state stays `ON`. In [[Fsm2]] it would have dropped to `OFF` the instant `areset` rose. Edges 5 and 6 are the toggle from Fsm2, unchanged.

## Gotchas / things to watch for

- **Comments copied from the previous problem will lie to you.** The pasted draft of this solution still said "Asynchronous reset" on the reset port and above the flop block, carried over from Fsm2, while the code is synchronous. The compiler checks none of that, and a reviewer reading the comments would come away with the wrong reset scheme. That's the most consequential possible mismatch for a reset, since sync vs. async changes timing closure, reset-tree design and how the block behaves before the clock starts. (The comments in `fsm2s.v` are corrected.) When you start a problem from the previous one's file, re-read every comment against the new spec. It's the same hygiene issue this repo has hit with whole README sections surviving a copy.
- **Sync vs. async is the sensitivity list, and only the sensitivity list.** Compare this flop block with Fsm2's: the `if (reset) ... else ...` is the same, and the only change is `, posedge areset` being gone. Two practical consequences. First, a synchronous reset does nothing until the clock ticks: if the clock isn't running, the machine stays `x`. Second, the reset passes through the same logic as any other data input, so synthesis may fold it into the next-state logic rather than using the flop's dedicated clear pin. Same theme as [[Fsm1s]], [[Lfsr5]] and [[Shift4]].
- **The port is called `reset` here and `areset` in Fsm2. That naming is a convention, so keep it.** Nothing enforces it, but `areset` (or `arst_n` for active-low) tells anyone instantiating the module that the reset bypasses the clock. A synchronous reset named `areset`, or the reverse, is a lie a reviewer has no reason to doubt. HDLBits renames the port between the two problems for exactly this reason.
- **`assign out = state;` is now the encoding-dependent version.** It works because `ON` happens to be 1. Swap the encoding and the output silently inverts. This is the trap described in [[Fsm1]]. `assign out = (state == ON);` costs nothing and says what the spec says. On the plus side, dropping the `===` from Fsm2 means a pre-reset `x` now shows up on `out` as `x` instead of a fake 0.
- **No `default` in the `case`**: harmless with a 1-bit state, a latch-in-waiting once there are unused codes. See [[Fsm1]] and [[Always_nolatches]].
- **`parameter` → `localparam` for the encodings**, as in [[Fsm1]].

## Solution

See `fsm2s.v`.
