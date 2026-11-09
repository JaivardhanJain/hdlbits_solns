# Fsm3

**HDLBits link:** https://hdlbits.01xz.net/wiki/Fsm3
**Category:** Circuits: Sequential (Finite State Machines)
**Difficulty:** ⭐⭐⭐

## Problem summary

The complete version of the four-state machine from [[Fsm3comb]] and [[Fsm3onehot]], with the same table: `A` goes to `B` on 1 and stays on 0; `B` stays on 1 and goes to `C` on 0; `C` goes to `D` on 1 and back to `A` on 0; `D` goes to `B` on 1 and `C` on 0; and `out` is 1 only in `D`. This time the module owns its own state register, with an asynchronous reset into `A`. Unlike the previous two problems, the encoding isn't specified. The only thing the grader can see is `out`.

## Approach

This is the [[Fsm1]] three-part template wrapped around the logic from [[Fsm3onehot]]:

1. **Next-state logic:** the four one-hot equations, each the OR of a state's in-edges, in an `always @(*)` block.
2. **State register:** a 4-bit `state` with async reset to `A = 4'b0001`.
3. **Output:** `out = state[3]`, i.e. "in `D`".

The interesting decision is the encoding itself. In [[Fsm3comb]] and [[Fsm3onehot]], `state` came in on a port, so the encoding was a contract with the testbench. Now `state` is internal. Binary (two flops, a `case` like Fsm3comb's) and one-hot (four flops, per-bit equations) are both correct, and nothing outside the module can tell them apart. This solution picks one-hot. That's a reasonable choice for an FPGA target, and it reuses Fsm3onehot's equations directly. Either way, it's a design decision, not a requirement.

A cycle-by-cycle trace that visits every state, starting from reset, with `in` = 1, 0, 1, 0, 0, 1, 1:

| Edge | `in` | `state` before | `next_state` | `state` after | `out` after |
|:----:|:----:|:--------------:|:------------:|:-------------:|:-----------:|
| reset | – | xxxx | – | A (0001) | 0 |
| 1 | 1 | A (0001) | B (0010) | B (0010) | 0 |
| 2 | 0 | B (0010) | C (0100) | C (0100) | 0 |
| 3 | 1 | C (0100) | D (1000) | D (1000) | 1 |
| 4 | 0 | D (1000) | C (0100) | C (0100) | 0 |
| 5 | 0 | C (0100) | A (0001) | A (0001) | 0 |
| 6 | 1 | A (0001) | B (0010) | B (0010) | 0 |
| 7 | 1 | B (0010) | B (0010) | B (0010) | 0 |

At every edge the register holds exactly one hot bit, and `out` is high only for the one cycle spent in `D`.

## Gotchas / things to watch for

- **The reset value is what makes one-hot work: reset to `0` and the machine is dead.** In [[Fsm3onehot]], all-zeros was an illegal input that the module merely had to tolerate. Now it can be *stored*. Every next-state equation needs some bit already hot, so `0000` maps to `0000` forever: no error, no `x`, `out` stuck at 0. Writing `state <= 0;` out of habit, as every reset in the chapter has so far, compiles and gives exactly that circuit. The same was true in [[Lfsr5]], where the reset *value* was a functional requirement rather than a formality. Here it has to be `A = 4'b0001`, and using the named parameter rather than a literal is what keeps it right.
- **The parameters are state *values* now, while the equations use bit *indices*, and only the comments link the two.** `A = 4'b0001` is the pattern, which is the opposite of [[Fsm3onehot]], where `A = 0` was a bit position. The equations, though, still use bare indices `state[0]` … `state[3]`, and `out = state[3]` means "in `D`" only because `D`'s hot bit happens to be bit 3. Re-assign `D = 4'b0100` and the reset still works, but every equation and the output now point at the wrong states, silently. The robust form keeps one source of truth: either index parameters (`localparam A_BIT = 0, …`) used both for the equations and to build the patterns (`4'b1 << A_BIT`), or the patterns used everywhere with a reduction (`|(state & D)`). Mixing a named reset with magic-number logic is the in-between that breaks.
- **Per-bit assignments in an `always @(*)` must cover every bit, or you get a latch.** All four `next_state[i]` are assigned on every pass, so the block is purely combinational. Drop one line and that bit keeps its old value, which is a latch, because this is a *combinational* block. In [[Fsm3onehot]] the same equations used `assign`, where a missing bit would have been undriven (`z`) instead. It's the same slip with a different symptom, and both are silent, which is the per-bit-assignment risk from [[Lfsr5]]. A habit that makes it impossible is to start the block with `next_state = 4'b0000;` and then set bits, the same "default first" pattern as [[Always_nolatches]].
- **The operators are consistent this time.** Every equation uses `&`, `|`, `~`, with none of the `&&`/`||` mix from [[Fsm3onehot]]. Note the precedence it relies on: `&` binds tighter than `|`, so `state[0] & ~in | state[2] & ~in` groups as intended without parentheses. That's worth knowing, but adding the parentheses costs nothing and saves the reader from checking.
- **Hand-coded one-hot may hide the FSM from synthesis.** FPGA tools find FSMs by spotting a state register driven through a `case` on its own value. They then report the states, can re-encode, and can add safe-state recovery. Equations on individual bits don't look like an FSM, so the tool just sees four flops and some logic, and you lose the FSM report and the tool's encoding options. The idiomatic version is to write symbolic states in a `case`, as in [[Fsm1]], and set the encoding with a synthesis attribute (for example `fsm_encoding = "one_hot"` in Vivado). That gives you this circuit and keeps the tool support. Hand-coding is still the right way to *understand* one-hot, which is what Fsm3onehot was for.
- **Recovery from illegal states is still absent.** The async reset puts the machine into a legal state, but nothing brings it back if a glitch or radiation upset produces `0000` or a two-hot pattern later. See [[Fsm3onehot]] for how those behave. It passes the grader, and in many designs a reset is the agreed recovery. Just be aware that one-hot gives you 12 illegal states to think about, where binary encoding of four states gives you none.

## Solution

See `fsm3.v`.
