# Exams_ece241_2013_q4

**HDLBits link:** https://hdlbits.01xz.net/wiki/Exams/ece241_2013_q4
**Category:** Circuits: Sequential (Finite State Machines)
**Difficulty:** ⭐⭐⭐

## Problem summary

A controller for a water reservoir. Three level sensors `S1` < `S2` < `S3` sit at different heights. The controller drives three nominal flow valves `fr1`–`fr3` and one supplemental valve `dfr`. The nominal flow depends only on the current level: all three valves below `S1`, `fr1`+`fr2` between `S1` and `S2`, `fr1` alone between `S2` and `S3`, and nothing above `S3`. The supplemental valve is the twist. In the two middle bands it opens only if the water got there by **falling**, i.e. the level before the last sensor change was higher. Below `S1` everything is open, including `dfr`. A synchronous active-high reset puts the controller in that "been empty for a long time" state, with all four outputs on. It's an exam problem (ECE241, 2013) where the original task was to draw the Moore state diagram. HDLBits asks for the Verilog.

## Approach

**Why six states.** The sensors give four possible levels (`s` = `000`, `001`, `011`, `111`), so a first guess is four states. But `dfr` depends on *history*: in the same band it's 1 if the water came down into it and 0 if it came up. A Moore output can only depend on state, so each middle band needs two states, one per direction. The two extreme bands don't: below `S1` everything is on and above `S3` everything is off, whichever way the water arrived. That gives 4 + 2 = **6 states**:

| State | Level | Arrived by | `fr3` | `fr2` | `fr1` | `dfr` |
|:-----:|:------|:-----------|:-----:|:-----:|:-----:|:-----:|
| `RST`  | below S1 (`000`) | either / reset | 1 | 1 | 1 | 1 |
| `FLS1` | S1–S2 (`001`) | rising | 0 | 1 | 1 | 0 |
| `FH1`  | S1–S2 (`001`) | falling | 0 | 1 | 1 | 1 |
| `FLS2` | S2–S3 (`011`) | rising | 0 | 0 | 1 | 0 |
| `FH2`  | S2–S3 (`011`) | falling | 0 | 0 | 1 | 1 |
| `FLS3` | above S3 (`111`) | either | 0 | 0 | 0 | 0 |

This is the general pattern for "Moore output depends on how we got here": you store the history as extra states. A Mealy machine could compare the old and new levels on the transition instead, but the spec asks for Moore.

**Transitions.** From any state, the new sensor reading gives the new level. If it's a middle level, the direction is set by whether the *old* level was above or below it. The code is the standard three-part template from [[Fsm1]]: a combinational `always @(*)` that starts with `next_state = state;` (hold by default) and then a nested `case` (outer on `state`, inner on `s`), a synchronous-reset state register, and one `assign` per output listing the states where it's on.

A trace filling and draining the reservoir, with one sensor change per step (outputs as `fr3 fr2 fr1 dfr`):

| Edge | `reset` | `s` | `state` after | Outputs | Why |
|:----:|:-------:|:---:|:-------------:|:-------:|:----|
| 1 | 1 | – | RST | 1111 | reset = "empty for a long time" |
| 2 | 0 | 001 | FLS1 | 0110 | rose into S1–S2: nominal only |
| 3 | 0 | 011 | FLS2 | 0010 | rose into S2–S3 |
| 4 | 0 | 111 | FLS3 | 0000 | full: flow off |
| 5 | 0 | 011 | FH2 | 0011 | fell into S2–S3: supplemental on |
| 6 | 0 | 001 | FH1 | 0111 | fell into S1–S2 |
| 7 | 0 | 011 | FLS2 | 0010 | rose again: supplemental off |
| 8 | 0 | 001 | FH1 | 0111 | fell again |
| 9 | 0 | 000 | RST | 1111 | empty |

Edges 5 and 7 show the whole point of the problem: `s = 011` both times, with different `dfr`, because the state remembers the direction.

## Gotchas / things to watch for

- **If the level skips a band, three states don't handle it and can get stuck.** Each state's inner `case` lists only the sensor codes the author expected next, and everything else falls through to the default `next_state = state`, i.e. hold. For `RST` and `FH2` every level is listed. For `FLS1`, `FLS2` and `FH1` the two-band jumps are missing, and holding is the wrong answer. Take `FLS2` (between S2 and S3, rising) when the reading drops straight to `000`. No branch matches, so it stays `FLS2`. Next cycle, still `000`, so it stays `FLS2` again, *forever*, outputting only `fr1` while the reservoir is empty: the opposite of what the spec wants. Similarly, `FLS1` seeing `111` sits in "S1–S2 rising" with two valves open while the tank overflows. `FLS3` handles a drop in yet a third way: it checks `s[3]` alone and always goes to `FH2`, which corrects itself a cycle later. HDLBits's testbench appears to change one sensor at a time, so this passes. But a slow clock, a sensor glitch or a fast drain can produce a skip in real life. A robust structure decides every transition from the *new level* alone (`000` → `RST`, `111` → `FLS3`), and for the middle levels compares old and new levels to pick the direction. Then every state handles every code, and there's no per-state list to get incomplete.
- **"Hold" as the default works for invalid patterns but hides missing transitions.** `next_state = state;` at the top of the block is the right latch-avoidance habit ([[Always_nolatches]]). For the four physically impossible patterns (`010`, `100`, `101`, `110`: a sensor above reads wet while one below reads dry), holding is a sensible response to a broken sensor. The trouble is that the same default also silently catches the *valid* codes a state forgot to list, which is exactly the bug above. A default that catches "can't happen" values should be kept separate from transitions that genuinely do happen.
- **`input [3:1] s` means `3'b001` is `s[1]`, not `s[3]`.** A literal's bits line up with the vector's declared range from the MSB: `s` is `[3:1]`, so `3'b001` sets the rightmost bit, which is index **1**, the lowest sensor. That's right here, and it reads naturally as "S3 S2 S1". But the literal knows nothing about the indices starting at 1. Declare the port `[1:3]` and the same literal means S3, and every comparison silently refers to the wrong sensor. This is the MSB-first rule from [[Vector0]] and [[Vector1]], applied to a vector that doesn't start at 0.
- **`fr1 = (state != FLS3)` is the one output written as an exclusion, and exclusions don't scale.** The other three outputs list the states where they're on. `fr1` lists where it's *off*, so any state added later turns `fr1` on by default, without anyone deciding that. With a small, fixed state set it's fine. In general, list states positively, or write the outputs as one `case (state)` that sets all four in each branch, which reads directly against the output table above.
- **The state names don't describe the states.** `FLS1`/`FLS2` are "rising", `FH1`/`FH2` "falling", and `FLS3` is the full state, which is reached from either direction but named as if it were a rising state. `RST` is a water level (below S1) named after the reset. Since names are the only documentation an FSM has, prefer level + direction: `BELOW_S1`, `S1_S2_UP`, `S1_S2_DN`, `S2_S3_UP`, `S2_S3_DN`, `ABOVE_S3`. Merging the reset into the "empty" state is correct, though: the spec defines the reset state as equivalent to having been low for a long time, and that's exactly `RST`'s outputs and future behaviour.
- **6 states in 3 bits leaves 2 unused codes, and the outer `default` covers them.** It's the situation [[Fsm3s]] got wrong. There, unused codes with no branch made `next_state` a latch. Here, the hold assignment at the top *and* the outer `default: next_state = RST;` mean both spare codes (`110`, `111`) recover to a known state. The `default` is what turns "can't happen" into "can't stay stuck".
- **This is the canonical case for a Moore machine needing more states than a Mealy one.** The same controller as a Mealy FSM needs only the four level states: `dfr` would be computed from the transition (old level vs. new level) instead of stored. The cost is that a Mealy output changes combinationally with `s`, glitches included, while a Moore output changes only on the clock. For a valve driver that's a real argument for Moore: you don't want a valve chattering because a sensor bounced mid-cycle.

## Solution

See `exams_ece241_2013_q4.v`.
