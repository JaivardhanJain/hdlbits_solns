# Exams_ece241_2013_q8

**HDLBits link:** https://hdlbits.01xz.net/wiki/Exams/ece241_2013_q8
**Category:** Circuits: Sequential (Finite State Machines)
**Difficulty:** ⭐⭐

## Problem summary

Detect the bit sequence `101` on the serial input `x`. `z` goes high in the same cycle as the final `1`. Overlapping sequences count, so `10101` contains two detections, sharing the middle `1`. It must be a **Mealy** machine with no more than **three** states, and it has an asynchronous, active-low reset (`aresetn`).

This is the first Mealy machine in the series. Every FSM so far had outputs depending on `state` alone.

## Approach

Each state records the longest prefix of `101` that the recent input matches:

| State | Recent input ends with | `x = 0` | `x = 1` | `z` |
|:-----:|:-----------------------|:-------:|:-------:|:---:|
| `RST`   | nothing useful | RST | GOT1 | 0 |
| `GOT1`  | `1` | GOT10 | GOT1 | 0 |
| `GOT10` | `10` | RST | GOT1 | **`x`** |

**Why Mealy needs only three states.** The output fires on the *transition* `GOT10 --1-->`, so `z = (state == GOT10) && x` is computed from the current state *and* the current input. A Moore version must have a fourth state, "just saw `101`", to hold the output for a cycle. That's the same reason [[Fsm_ps2]] needed four states rather than three, and it's why [[Exams_ece241_2013_q4]] needed extra states to remember history. Mealy uses the input itself as part of the output decision and saves that state.

**Overlap lives in two arrows.** `GOT10 --1--> GOT1`: the final `1` of one match is the first `1` of the next. And `GOT1 --1--> GOT1`: in `11`, the most recent `1` is still a valid start. Neither arrow goes back to `RST`.

A trace on `x = 1 0 1 0 1 1 0 1`. Note that `z` is high *during* the cycle the final `1` is on the input, not the cycle after.

| Cycle | `x` | `state` | `z` | `next_state` | |
|:-----:|:---:|:-------:|:---:|:------------:|:--|
| 1 | 1 | RST | 0 | GOT1 | |
| 2 | 0 | GOT1 | 0 | GOT10 | |
| 3 | 1 | GOT10 | **1** | GOT1 | `101` |
| 4 | 0 | GOT1 | 0 | GOT10 | |
| 5 | 1 | GOT10 | **1** | GOT1 | `101` again, overlapping cycle 3's final `1` |
| 6 | 1 | GOT1 | 0 | GOT1 | `11`: keep the latest `1` |
| 7 | 0 | GOT1 | 0 | GOT10 | |
| 8 | 1 | GOT10 | **1** | GOT1 | `101` |

## Gotchas / things to watch for

- **`state` is 3 bits wide and the `case` has no `default`, so `next_state` becomes a latch.** It's the [[Fsm3s]] bug again, and here *two* things combine. Three states need only 2 bits, so `logic [2:0]` adds four unused codes (4–7). But even at the right width, `[1:0]`, three states leave code 3 unused. Either way, some value of `state` matches no branch, `next_state` isn't assigned, and the `always_comb` describes a latch. (SystemVerilog tools will at least warn, because `always_comb` is supposed to be latch-free: that's one of its benefits, flagged in [[Fsm1]].) The grader never sees it, because reset and the transitions only ever produce 0–2. Whenever the state count isn't a power of two, a `default` is required, not optional. Add `default: next_state = RST;` and size the register `[1:0]`.
- **A Mealy output is combinational from the input, with consequences.** `z` changes as soon as `x` does, within the cycle, so (a) any glitch on `x` can glitch `z`, and (b) there's a combinational path from the `x` pin to the `z` pin through this module. If the consumer is another Mealy machine, the paths chain together, and long Mealy chains are a classic source of timing failures and, in the worst case, combinational loops. A Moore output avoids both at the cost of a cycle of latency and an extra state. If you need Mealy's timing but a clean output, the usual fix is to register `z` after computing it, which effectively makes it Moore again, one cycle later.
- **Reading `z` in a waveform: Mealy outputs line up with the input, not the next state.** In the trace, `z` is high in cycle 3, the cycle `x = 1` completes the pattern, while `state` is still `GOT10`. With a Moore detector, the pulse would appear in cycle 4, in the new state. Off-by-one confusion between "the cycle the input matched" and "the cycle after" is how testbenches for these get written wrong, so check which convention the spec means.
- **Getting the overlap arrows wrong compiles, and still finds some matches.** Sending `GOT10 --1-->` back to `RST` instead of `GOT1` misses the second `101` in `10101`. Sending `GOT1 --1-->` to `RST` misses every pattern that starts in a run of 1s, like `1101`. Each mistake still passes tests that happen to avoid the case it breaks. The rule: after any input, go to the state for the *longest suffix of the input so far* that's still a prefix of the pattern. It's the same principle as the KMP string-matching failure function.
- **Active-low async reset: `negedge` in the sensitivity list and `~aresetn` in the `if`.** Both must agree. `posedge aresetn` with `if (~aresetn)` would trigger on the release edge and then test a signal that's already high, so the reset branch never runs at the edge that triggered it. The `n` suffix in the name is what keeps the two consistent: see [[Exams_m2014_q4k]] on carrying active-low naming through every level. The usual production caveat from [[Dff8ar]] applies too: assert asynchronously, release synchronously.
- **Moore vs. Mealy is about where the output is computed, not about what it can detect.** Any Mealy machine can be converted to Moore by adding states to remember the condition for one cycle, and the reverse often saves states. This problem's 3-state limit is HDLBits forcing the Mealy form. The next pair, [[Exams_ece241_2014_q5a]] and [[Exams_ece241_2014_q5b]], solves the same task both ways, which makes the trade-off concrete.

## Solution

See `exams_ece241_2013_q8.v`.
