# Dff8ar

**HDLBits link:** https://hdlbits.01xz.net/wiki/dff8ar
**Category:** Circuits: Sequential (Latches and Flip-flops)
**Difficulty:** ⭐⭐

## Problem summary

Eight D flip-flops on the rising edge of `clk`, with an active-high **asynchronous** reset that forces `q` to zero the instant `areset` goes high, without waiting for a clock edge.

## Approach

The body of the always block is byte-for-byte the same as [[Dff8r]] — `if (areset) q <= 8'b0; else q <= d;`. The only change that makes the reset asynchronous is adding `posedge areset` to the sensitivity list:

```verilog
always @(posedge clk, posedge areset)
```

That single edit is the whole problem, and it's worth pausing on *why* it works, because on first read the sensitivity list looks like it's describing the wrong thing.

### Why `posedge areset` models a level-sensitive reset

A real flip-flop's asynchronous reset pin responds to the **level** of the signal: as long as `areset` is high, `q` is held at 0. But the sensitivity list is written in terms of an *edge*. The two turn out to be equivalent because of what happens on each possible event, assuming `clk` and `areset` never switch at exactly the same moment:

| Event | Block runs? | Result |
|---|:---:|---|
| `areset` 0→1 | yes | `areset` is high, so `q <= 0` — reset takes effect immediately, no clock needed |
| `areset` 1→0 | no | nothing happens, and nothing needs to: `q` is already 0 and just holds |
| `clk` 0→1, `areset` low | yes | normal capture, `q <= d` |
| `clk` 0→1, `areset` high | yes | `q <= 0` again — already 0, so no visible change |
| `clk` 1→0 | no | flip-flop ignores the falling edge |

The only row where level-sensitivity and edge-sensitivity could disagree is "`areset` is high and stays high" — and in that state `q` was already driven to 0 by the rising edge that got us there, so there is nothing left to do. The edge trigger is sufficient to reproduce level behaviour precisely because the reset is idempotent.

## Gotchas / things to watch for

- **`posedge areset` in the sensitivity list is a synthesis idiom, not a general Verilog pattern.** It reads like it's modelling an edge-triggered reset, and the reasoning above is what makes it correct — but the deeper point is that synthesis tools *pattern-match* this exact form. `always @(posedge clk, posedge areset)` with `if (areset)` as the first branch is the recognized recipe for "infer a flop with an async clear." Deviate from it — reset checked second, an extra signal in the sensitivity list, a compound condition like `if (areset & enable)` — and the tool will either error out or quietly infer something you didn't intend. Write it the canonical way even when a variant seems logically equivalent.
- **Active-low reset needs `negedge`, not `posedge`.** The sensitivity list edge must match the polarity that *asserts* the reset. A signal named `areset_n` that resets when low needs `always @(posedge clk, negedge areset_n)` with `if (!areset_n)`. Mismatching the two (`negedge` in the list but `if (areset_n)` in the body) is a common bug that still compiles and still infers a flop — it just resets at the wrong times.
- **The reset signal must be checked *before* anything else in the block.** Async reset has to override the clocked path unconditionally, so `if (areset)` goes first with no competing condition ahead of it. Any structure that lets a clocked assignment win over reset breaks the "asynchronous" contract.
- **Sync vs. async is a design decision, not a style preference.** This chapter has now built both ([[Dff8r]] synchronous, this one asynchronous) from nearly identical code, which makes them look interchangeable. They aren't. Synchronous reset costs a mux in front of D and is easy for timing analysis; asynchronous reset uses a dedicated flop pin, works even with the clock stopped, but introduces a genuine hazard — if `areset` *de-asserts* too close to a clock edge, the flop can go metastable. That's why production designs almost always assert reset asynchronously and **de-assert it synchronously** through a reset synchronizer, rather than letting a raw async reset release whenever it likes.
- **`,` and `or` mean the same thing here.** `always @(posedge clk, posedge areset)` and `always @(posedge clk or posedge areset)` are identical. The comma is the modern form and is safer in combinational blocks where `or` can be visually confused with the bitwise operator; either is accepted.
- **Declare `q` as `reg` when you assign it procedurally.** HDLBits's given port list says `output [7:0] q`, which works on their grader because it compiles as SystemVerilog (where a bare `output` defaults to a four-state `logic` that procedural code may drive). In strict Verilog-2001 an output assigned inside an `always` block must be `output reg [7:0] q`, and a stricter linter or an older toolchain will reject the bare form. Writing `reg` explicitly costs nothing and keeps the file portable.
- **`q <= 0` works, but write `8'b0`.** An unsized `0` zero-extends to the target width and is harmless here, but it's the same habit that made `34` mean `0x22` in [[Dff8p]]. Sizing every literal is cheap insurance — see [[Step One]].

## Solution

See `dff8ar.v`.
