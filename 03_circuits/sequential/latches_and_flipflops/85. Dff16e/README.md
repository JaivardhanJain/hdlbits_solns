# Dff16e

**HDLBits link:** https://hdlbits.01xz.net/wiki/dff16e
**Category:** Circuits: Sequential (Latches and Flip-flops)
**Difficulty:** ⭐⭐⭐

## Problem summary

A 16-bit register with a **byte enable**: each half of the register updates independently. `byteena[1]` gates the upper byte `d[15:8]`, `byteena[0]` gates the lower byte `d[7:0]`, and a byte whose enable is low simply holds whatever it had. `resetn` is a synchronous, active-low reset that clears all 16 bits regardless of the enables.

## Approach

This is the first problem in the chapter where different bits of the same register do different things on the same clock edge, so the single whole-vector assignment used since [[Dff8]] no longer covers it. The register splits into two independently-controlled slices.

Priority matters and falls out of the nesting:

1. **Reset first.** `if (~resetn)` is the outer condition, so reset beats both enables — a reset with `byteena = 2'b00` still clears the register. The spec says reset is unconditional, and putting it outermost is what encodes that.
2. **Then the per-byte enables**, checked independently inside the `else`. They're two separate `if` statements rather than one `if/else`, because the bytes aren't mutually exclusive — both can be enabled on the same cycle, or neither.

Because `resetn` is active-low, the test is `~resetn` (true when the signal is 0). Everything stays inside `always @(posedge clk)` with no reset in the sensitivity list, since this reset is synchronous — same rule as [[Dff8r]].

## Gotchas / things to watch for

- **The `else q[15:8] <= q[15:8];` hold branches are unnecessary.** This is the main thing worth understanding here. The instinct to write them comes from the latch-inference rule drilled into every Verilog course: *in a combinational block, an incompletely-specified `if` infers a latch, so always assign in every branch.* That rule is real, but it is a rule about **combinational** always blocks. Inside `always @(posedge clk)`, "no assignment on this path" doesn't mean "undefined" — it means the flip-flop simply isn't loaded on that edge and keeps its previous value, which is exactly the hold behaviour you wanted. Memory is the *point* of a clocked block; there's nothing to accidentally infer. `alt1.v` shows the same circuit with both hold branches deleted, and it synthesizes identically: the enable becomes a clock-enable pin (or a mux in the D path) on those eight flops either way.

  Writing the explicit self-assignment isn't *wrong* — it's not a bug, and some house styles prefer the symmetry — but it's noise, and at scale it actively hurts readability: a 40-line state machine where every branch redundantly restates every register it isn't changing buries the handful of assignments that actually matter. The industry-common convention is to let a clocked block's unassigned paths mean "hold" and reserve exhaustive assignment for combinational blocks, where it's mandatory.

- **The latch rule inverts between the two block types — know which one you're in.** In `always @(*)`, a missing branch is a bug (it creates a latch you didn't ask for). In `always @(posedge clk)`, a missing branch is the normal way to express "hold." Same syntax, opposite meaning, decided entirely by the sensitivity list. HDLBits drills the combinational half of this in its Procedures chapter (`always_if2`, `always_nolatches`); this problem is where the sequential half shows up.

- **Two independent `if`s, not `if`/`else if`.** Chaining them (`if (byteena[1]) ... else if (byteena[0]) ...`) creates a priority relationship that isn't in the spec: with `byteena = 2'b11` only the upper byte would load. The enables are orthogonal, so they need orthogonal statements.

- **Active-low means testing `~resetn`, and the polarity is easy to flip.** `if (resetn)` compiles fine and produces a register that resets exactly when it shouldn't. When a signal's name ends in `n`, the assertion test should have a negation in it — treat a missing `~` as a red flag. (In an `if` condition, `!resetn` is arguably the more precise choice over `~resetn` — logical vs. bitwise, the distinction from [[Norgate]] — though on a 1-bit signal they're equivalent and `~` is common in practice.)

- **Part-select bounds must be constants and must match the declared direction.** `q[15:8]` and `d[15:8]` line up here, but writing `q[8:15]` — descending declaration, ascending select — is a syntax error, not a reversal. Same rule established back in [[Vector1]].

- **Assigning to slices of `q` still requires `q` to be a `reg`.** Procedural assignment to a part-select is procedural assignment; HDLBits's bare `output [15:0] q` only works because their grader compiles as SystemVerilog. `output reg [15:0] q` keeps it valid Verilog-2001 — same note as [[Dff8ar]].

## Solution

See `dff16e.v` (explicit hold branches, as written) and `alt1.v` (the same circuit with the redundant holds removed).
