# Fsm2

**HDLBits link:** https://hdlbits.01xz.net/wiki/Fsm2
**Category:** Circuits: Sequential (Finite State Machines)
**Difficulty:** ⭐⭐

## Problem summary

A two-state Moore machine with two inputs and an asynchronous reset into `OFF`. In `OFF` the output is 0, and the machine moves to `ON` when `j` is 1. In `ON` the output is 1, and it moves back to `OFF` when `k` is 1. Otherwise it stays where it is. HDLBits's hint gives the game away: this is a JK flip-flop, described as a state diagram instead of a characteristic table.

## Approach

It's the same three-part template as [[Fsm1]]: a combinational `case` for the next state, one clocked block for the state register with the async reset, and an `assign` for the Moore output. The only new thing is that there are two inputs, and each state looks at just one of them:

- In `OFF`, only `j` matters. `k` is a don't-care, because there's no arrow out of `OFF` that depends on it.
- In `ON`, only `k` matters, and `j` is the don't-care.

So each `case` branch is a single ternary on one input. Writing the don't-cares this way, by simply not mentioning the other input, is what keeps the next-state logic as small as the diagram.

A trace from reset that walks through all four `{j, k}` combinations, so the JK behaviour is visible:

| Edge | `j` | `k` | `state` before | `state` after | `out` after | JK reading |
|:----:|:---:|:---:|:--------------:|:-------------:|:-----------:|:-----------|
| reset | – | – | x | OFF | 0 | clear |
| 1 | 0 | 0 | OFF | OFF | 0 | hold |
| 2 | 1 | 0 | OFF | ON | 1 | set |
| 3 | 0 | 0 | ON | ON | 1 | hold |
| 4 | 1 | 1 | ON | OFF | 0 | toggle |
| 5 | 1 | 1 | OFF | ON | 1 | toggle |
| 6 | 0 | 1 | ON | OFF | 0 | reset |
| 7 | 0 | 1 | OFF | OFF | 0 | reset (already 0) |

Edges 4 and 5 are the interesting ones. Nobody wrote a "toggle" case. It falls out of the two don't-cares: with `j = k = 1`, `OFF` sees `j` and leaves, and `ON` sees `k` and leaves. The JK flip-flop's whole characteristic table comes from two one-input arrows.

## Gotchas / things to watch for

- **`always_comb` and a plain Verilog `always @(...)` in the same module — pick one dialect.** The next-state block is SystemVerilog and the state register is Verilog-2001. Both compile on HDLBits, which accepts SystemVerilog, but the file now builds in neither strict flow: a Verilog-2001 tool rejects `always_comb`, and a SystemVerilog lint wants `always_ff` for the flop. [[Fsm1]] used `always_comb`/`always_ff` throughout. Either do that (in a `.sv` file) or use `always @(*)` / `always @(posedge clk, posedge areset)` throughout. The mixed version gives you the latch check on one block and not the flop check on the other.
- **`===` again.** The same issue as [[Fsm1]]: before reset, `state` is `x`, `state === ON` is a clean 0, and the uninitialized output is hidden as a believable `OFF`. Here that's worse than in Fsm1, because 0 is also the *legitimate* reset value. The waveform before and after reset looks identical. Use `state == ON` and the pre-reset `x` shows up as `x`.
- **Don't-cares are expressed by not mentioning the input — don't "complete" the logic.** It's tempting to write `OFF: next_state = (j & ~k) ? ON : OFF;`, on the theory that the spec "really" means set only when `k` is low. That's a different circuit: with `j = k = 1` it holds instead of toggling, which makes it an SR-style latch rather than a JK. The diagram has no `k` on `OFF`'s arrows, so `k` must not appear in that branch. Read the conditions off the arrows exactly, and add nothing.
- **Same `case`-without-`default` situation as [[Fsm1]].** It's fine with a 1-bit state whose two values are both covered, and a latch-in-waiting once the encoding has spare codes. Add `default: next_state = OFF;` now. See [[Always_nolatches]].
- **The reset state is 0 this time, where Fsm1's was 1.** `areset` maps to an async *clear* here, against Fsm1's async *preset*. It's the same template. Always take the reset value from the spec, never from the previous problem.
- **`parameter` vs. `localparam` and encoding-dependent outputs, as in [[Fsm1]].** `ON` happens to be 1, so `assign out = state;` would pass and silently invert if the encoding were ever swapped. `state == ON` ties the output to the state's name. Encodings belong in `localparam` (or a SystemVerilog `enum`).
- **Yes, `state <= j & ~state | ~k & state;` is the whole thing.** It's the JK characteristic equation, and it's correct. But you can't check it against the diagram without re-deriving it, and that's the reason the template is worth its extra lines.

## Solution

See `fsm2.v`.
