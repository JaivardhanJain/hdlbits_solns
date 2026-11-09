# Fsm3comb

**HDLBits link:** https://hdlbits.01xz.net/wiki/Fsm3comb
**Category:** Circuits: Sequential (Finite State Machines)
**Difficulty:** ⭐⭐

## Problem summary

A four-state Moore machine, specified as a state-transition table, with one input `in` and one output `out`. Unlike the earlier FSMs, there's no clock, no reset and no state register. The current `state` comes in on a port, and the module only computes `next_state` and `out`. In other words, this is the combinational half of the FSM template on its own. The encoding is fixed by the problem: `A = 00`, `B = 01`, `C = 10`, `D = 11`, and `out` is 1 only in `D`.

## Approach

These are parts 1 and 3 of the three-part template from [[Fsm1]], with part 2 (the state flop) removed:

- **Next-state logic:** one `case` branch per row of the table, each a single ternary on `in`. Every line reads straight off one row, so checking the code against the spec is a row-by-row comparison.
- **Output logic:** Moore, so `out` depends on `state` alone: `state == D`.

Because the module is purely combinational, it can be checked *exhaustively*. There are only eight `(state, in)` combinations:

| `state` | `in` | `next_state` | `out` |
|:-------:|:----:|:------------:|:-----:|
| A (00) | 0 | A (00) | 0 |
| A (00) | 1 | B (01) | 0 |
| B (01) | 0 | C (10) | 0 |
| B (01) | 1 | B (01) | 0 |
| C (10) | 0 | A (00) | 0 |
| C (10) | 1 | D (11) | 0 |
| D (11) | 0 | C (10) | 1 |
| D (11) | 1 | B (01) | 1 |

That table *is* the spec, and the grader is effectively checking these eight rows. This is the real reason HDLBits splits the problem off: separate the logic from the flop and you can verify it completely, before a clock is involved. With a register in the loop, you'd be checking sequences instead of rows.

## Gotchas / things to watch for

- **`next_state` is a plain `output` but assigned inside `always_comb`, and that's HDLBits's own header.** A procedural assignment needs a variable, so the portable declaration is `output reg [1:0] next_state` (or `output logic [1:0] next_state` in SystemVerilog). The bare form passes only because HDLBits's compiler is lenient about it. Strict Verilog-2001 rejects it, and so do strict SystemVerilog tools, because an output with no data type defaults to a net. This is the same situation as [[Lfsr5]], where the *provided* header is the non-portable one. It's also the inverse of [[Exams_ece241_2013_q12]], where `reg` was added and then driven by an `assign`. `out`, driven by `assign`, is correctly left as a plain `output`. Two outputs in one module get opposite declarations, decided by how each is driven.
- **The encoding is now part of the interface, not an internal choice.** In [[Fsm1]] the advice was to treat the encoding as an implementation detail. Here `state` arrives on a port, so `A = 0 … D = 3` is a contract with whoever drives that port, which is the grader's testbench. Pick different values and the logic is internally consistent but wrong at every row. Keep using the names (`state == D`, not `state == 2'd3`, and definitely not `&state`). But the values come from the spec, and they're still best as `localparam`, so nothing outside can override them.
- **All four values are covered, so synthesis won't infer a latch — but simulation can hide an `x`.** A 2-bit `state` has exactly four values, and every one has a branch, so it's a full case. But if `state` is `x` (say, an upstream register that hasn't been reset yet), no branch matches, nothing is assigned, and in simulation `next_state` quietly keeps its previous value. It doesn't go to `x`. The bug is invisible exactly when you'd want to see it. Adding `default: next_state = 2'bx;` makes simulation propagate the `x`, and tells synthesis the case is don't-care. Or use `default: next_state = A;` if you'd rather the hardware fall back to a safe state. Either is better than nothing. It's the same habit urged in [[Fsm1]] and [[Always_nolatches]], but the reason this time is debuggability rather than latches.
- **`==`, not `===`.** It's the one thing that was wrong in [[Fsm1]] and [[Fsm2]] and is right here. If `state` is `x`, `out` is `x` too, which is correct for the same reason as the `default` above: an undefined input should look undefined.
- **Don't add a clock "to make it an FSM".** The module is meant to have none. The state register lives elsewhere (in the next problems, back inside your module). Putting an `always @(posedge clk)` here, or making `out` registered, would break the contract that `next_state` and `out` respond to `state` and `in` immediately.

## Solution

See `fsm3comb.v`.
