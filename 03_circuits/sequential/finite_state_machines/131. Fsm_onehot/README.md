# Fsm_onehot

**HDLBits link:** https://hdlbits.01xz.net/wiki/Fsm_onehot
**Category:** Circuits: Sequential (Finite State Machines)
**Difficulty:** ⭐⭐⭐⭐

## Problem summary

A 10-state Moore machine (`S0`–`S9`), given as a state diagram, with one input and two outputs. As in [[Fsm3onehot]], the module is purely combinational: `state` arrives one-hot on a 10-bit port, and the module produces `next_state` and the outputs. The equations must be derived by inspection, and the testbench deliberately feeds in states that aren't one-hot to check that you did.

The machine counts consecutive 1s. `S1`–`S6` mean "seen 1 to 6 ones in a row", and any 0 before the fifth one sends it back to `S0`. After five ones, a 0 goes to `S8` (`out1`). After six, a 0 goes to `S9` (both outputs). A seventh 1 goes to `S7` (`out2`), which stays there on further 1s. From `S8`/`S9` a 1 starts a new run at `S1`, and from `S7` a 0 resets to `S0`. If that looks familiar, it's the skeleton of HDLC bit-stuffing and flag detection, which comes back as [[Fsm_hdlc]].

| State | in = 0 | in = 1 | `out1` | `out2` |
|:-----:|:------:|:------:|:------:|:------:|
| S0 | S0 | S1 | 0 | 0 |
| S1 | S0 | S2 | 0 | 0 |
| S2 | S0 | S3 | 0 | 0 |
| S3 | S0 | S4 | 0 | 0 |
| S4 | S0 | S5 | 0 | 0 |
| S5 | S8 | S6 | 0 | 0 |
| S6 | S9 | S7 | 0 | 0 |
| S7 | S0 | S7 | 0 | 1 |
| S8 | S0 | S1 | 1 | 0 |
| S9 | S0 | S1 | 1 | 1 |

## Approach

The same method as [[Fsm3onehot]], at a scale where shortcuts become tempting. For each state, list the arrows that land *on* it, and OR them:

| Next state | In-edges | Terms |
|:----------:|:---------|:-----:|
| S0 | S0, S1, S2, S3, S4, S7, S8, S9 on 0 | 8 |
| S1 | S0, S8, S9 on 1 | 3 |
| S2–S6 | the previous state on 1 | 1 each (5) |
| S7 | S6, S7 on 1 | 2 |
| S8 | S5 on 0 | 1 |
| S9 | S6 on 0 | 1 |

Sanity check: 10 states × 2 input values = **20 arrows**, and 8 + 3 + 5 + 2 + 1 + 1 = **20 terms**. Each arrow appears exactly once. With ten equations, this count is the cheapest way to catch a missing or duplicated term.

`S0` is the big one, because nearly every state falls back to it on a 0. Instead of eight separate terms, the solution uses the fact that `S0`–`S4` and `S7`–`S9` occupy contiguous bit ranges: `state[4:0] || state[9:7]`. The outputs are each an OR of the states where they're on: `out1` in `S8`/`S9`, `out2` in `S7`/`S9`.

A trace covering every output combination, starting in `S0`:

| Step | `in` | `state` | `next_state` | `out1 out2` (of `state`) |
|:----:|:----:|:-------:|:------------:|:------------------------:|
| 1–5 | 1,1,1,1,1 | S0→S1→S2→S3→S4 | → S5 | 0 0 |
| 6 | 0 | S5 | S8 | 0 0 |
| 7 | 1 | S8 | S1 | **1 0** |
| 8–12 | 1,1,1,1,1 | S1→…→S5 | → S6 | 0 0 |
| 13 | 0 | S6 | S9 | 0 0 |
| 14 | 0 | S9 | S0 | **1 1** |
| 15–20 | 1 ×6 | S0→…→S6 | → S7 | 0 0 |
| 21 | 1 | S7 | S7 | **0 1** |
| 22 | 0 | S7 | S0 | 0 1 |

And the two inputs that matter for grading, both from the testbench's non-one-hot checks or near them:

| `state` | `in` | Correct `next_state` |
|:--------|:----:|:---------------------|
| S5 only (`0000100000`) | 0 | S8 only |
| none (`0000000000`) | 0 | none: nothing is hot, so nothing flows anywhere |

## Gotchas / things to watch for

- **Don't write a one-hot bit as "every state except…". That was the first draft's bug.** Because `S0` has eight in-edges and only two non-in-edges, the natural shortcut is to describe it by exclusion: "on 0, go to `S0` unless we're in `S5` or `S6`". The first draft wrote exactly that: `next_state[S0] = ~in && (~state[S5] || ~state[S6]);`. It's wrong twice over.
  - **The logic.** "Not `S5` or not `S6`" is true whenever *either* bit is clear, which, for a one-hot state, is every state. With `state = S5` and `in = 0`, `~state[S5] || ~state[S6]` = `0 || 1` = 1, so `S0` turns on alongside the correct `S8`, and the result is two-hot. The intended condition was `~state[S5] && ~state[S6]` (De Morgan: *not (A or B)* is *not A and not B*).
  - **The approach.** Even with De Morgan fixed, it still fails. An exclusion equals the in-edge OR only when *exactly one* bit is hot, and HDLBits specifically tests inputs where that isn't true. With `state = 0000000000` and `in = 0`, "not `S5` and not `S6`" is true, so `S0` lights up out of nothing. The in-edge OR is false, because no state is hot, so nothing should arrive anywhere. One-hot next-state logic says "be hot if a predecessor was hot and its arrow fired". An exclusion says "be hot unless…", which is a different function that happens to agree on the 10 legal inputs and disagrees on the other 1014. This is the in-edge rule from [[Fsm3onehot]], and the 20-arrow count above is the check that would have flagged it: the exclusion version has no countable terms at all.
- **`state[4:0] || state[9:7]` only works because `||` is logical.** `||` treats each operand as a single truth value: a vector is "true" if any bit is set. So this is "any of `S0`–`S4` *or* any of `S7`–`S9`", which is exactly the 8-term OR. Now consider the near-miss that mixes in bitwise operators, `~in & (state[4:0] | state[9:7])`. `state[4:0] | state[9:7]` is a bitwise OR of a 5-bit and a 3-bit vector (zero-extended to 5), giving a 5-bit result. `~in` is extended to 5 bits to match. The 5-bit AND is then truncated into the 1-bit `next_state[S0]`, which keeps only bit 0, `~in & (state[0] | state[7])`. It compiles silently and drops six of the eight in-edges. The [[Norgate]] distinction usually costs a wrong polarity; here it costs most of an equation. The robust spelling makes the reduction explicit, whichever operator you use around it: `~in & (|state[4:0] | |state[9:7])`. The unary `|` turns each range into one bit *before* anything gets combined.
- **The bit-range shortcut quietly depends on the encoding.** Every other line uses the names `S0`…`S9`, but `state[4:0]` and `state[9:7]` are bare numbers that are right only because `S0`–`S4` and `S7`–`S9` happen to be contiguous indices. Renumber a state and the named equations follow it, but the ranges don't. It's the same name-vs-magic-number split flagged in [[Fsm3]]. Keep the ranges, since they're much more readable than eight terms, but put a comment next to them listing which states they cover. The solution's comment does this.
- **`next_state` is a plain `output` driven from `always_comb`.** It's HDLBits's header, and it passes because the compiler is lenient. Strict tools want `output logic [9:0] next_state`. See [[Fsm3comb]]. Every one of the ten bits is assigned in the block, so there's no latch, but a forgotten line would make one (see [[Fsm3]]).
- **One-hot output decode is an OR of state bits, and you get it free.** `out1 = S8 | S9` and `out2 = S7 | S9` are two-input ORs, with no comparators. With a binary 4-bit encoding, each output would decode four bits per state. Ten states with outputs on a handful of them is exactly the case where one-hot pays off (see [[Fsm3onehot]]).
- **`~` with `&&`/`||`.** As in [[Fsm3onehot]], it's correct on single bits, but it's a mix of bitwise negation and logical operators. Combined with the previous gotcha, this is the problem where that mix stops being cosmetic: once a vector shows up as an operand, logical and bitwise operators compute different things.

## Solution

See `fsm_onehot.v`.
