# Count10

**HDLBits link:** https://hdlbits.01xz.net/wiki/count10
**Category:** Circuits: Sequential (Counters)
**Difficulty:** ⭐⭐

## Problem summary

Build a decade counter: 4 bits wide, counting 0 → 9 and then back to 0, i.e. a period of 10. Synchronous active-high `reset` forces the count to 0 on the next rising edge.

## Approach

This is [Count15](../98.%20Count15/README.md) with the one crutch removed. There, the period was 16 and the register was 4 bits wide, so the wraparound came free from the discarded carry out of bit 3 — nothing in the code mentioned 15. Here the period is 10, which is *not* a power of two, so the counter has to be told where to stop:

```verilog
always @ (posedge clk) begin
    if (reset)          q <= 4'd0;
    else if (q == 4'd9) q <= 4'd0;
    else                q <= q + 4'd1;
end
```

The `if`/`else if`/`else` chain is a priority structure, and the priority order here is deliberate: **reset beats terminal count beats increment.** That matters — if the counter happens to be sitting at 9 when `reset` asserts, both conditions are true, and the chain guarantees reset wins. In this particular case both branches assign 0 so the outcome is the same either way, but that's an accident of the reset value, not something to rely on. Get into the habit of putting reset first unconditionally; the moment the reset value isn't the same as the wrap value (as in [Count1to10](../) next door, which resets to 1), the ordering becomes load-bearing.

Note what the terminal-count test compares against: **9, not 10.** The check runs *before* the increment, using the current value, and it means "if I'm at 9 right now, the next value is 0 instead of 10." Testing `q == 4'd10` would let 10 actually appear on the output for a cycle, giving a period of 11.

The extra logic this costs is exactly what Count15 avoided: a 4-input equality comparator on `q`, feeding a mux that chooses between `4'd0` and `q+1`. That's the price of a non-power-of-two period, and it's unavoidable — every counter in the rest of this chapter (Count1to10, the BCD counters, the 12-hour clock) pays some version of it.

## Gotchas / things to watch for

- **`===` instead of `==` — the big one, and it isn't synthesizable.** `===` is Verilog's *case equality* operator: it compares `x` and `z` bits literally and always returns a clean 0 or 1, never `x`. Real hardware has no such comparator — a physical wire is high or low, there is no gate that can ask "is this bit metastable-unknown?" — so `===` exists only for simulation and testbench code. Most synthesis tools reject it outright; the ones that don't will silently treat it as `==`, meaning your simulation and your silicon are running different logic. Use `==` in anything you intend to synthesize, and reserve `===`/`!==` for testbenches (where being able to write `if (dut_out !== expected)` and catch an `x` is genuinely useful). This is the first appearance in the series of a construct that *simulates fine and cannot be built* — a distinct category from the ordinary bugs so far, and worth internalizing early.

- **The reason `===` is tempting here is the reason it's dangerous.** Before the first reset, `q` is `x`. With `==`, `x == 4'd9` evaluates to `x`, `if (x)` is treated as false, so control falls to `q <= q + 1` — which is still `x`. With `===`, `x === 4'd9` is cleanly false and you get the same fall-through. So the two behave identically here and `===` looks like it's "safely" handling the unknown. It isn't handling anything; it's hiding the fact that the counter is undefined until reset. If you find yourself reaching for `===` to make a warning go away in synthesizable code, the actual fix is almost always a reset, not a different equality operator.

- **Unsized literals: `q <= 0`, `q == 9`, `q + 1`.** These all work — the unsized decimals are 32-bit by default and get truncated or context-widened to fit the 4-bit target. But it's the same discipline flagged in [Count15](../98.%20Count15/README.md) and traceable back to [Step One](../../../../01_getting_started/): write literals at the width of the signal they touch (`4'd0`, `4'd9`, `4'd1`). Comparisons are a slightly sharper case than assignments, because `==` has no assignment target to set the context — the operands are extended to the *wider* of the two, so `q == 9` compares a zero-extended 4-bit `q` against a 32-bit 9. It still gives the right answer, but it means the expression's width depends on something that isn't visible in the line you're reading.

- **Off-by-one in the terminal count.** Comparing against 10 instead of 9 gives a period of 11 and lets an out-of-spec value reach the output. The mental model that avoids it: the comparison asks about the value *you already have*, while the assignment sets the value you'll have *next*. Same one-cycle offset as the shadow register in [Edgedetect](../../latches_and_flipflops/94.%20Edgedetect/README.md) — old value on the right of `<=`, new value on the left.

- **Relying on the 4-bit width to wrap, as Count15 did.** `q <= q + 4'd1` alone gives a period of 16, not 10, because the register width and the period are no longer the same number. Count15's elegance was specific to 16 = 2⁴; carrying that instinct forward is exactly the trap this problem is positioned to catch.

- **`>= 9` vs `== 9` — equivalent here, but not always.** `if (q >= 4'd9)` also works and is arguably safer: if the counter ever lands in the unreachable 10–15 range (a glitch, a badly-initialized register, an SEU in a radiation environment), `>=` recovers to 0 on the next edge while `==` leaves it counting up to 15 and around, taking six extra cycles to rejoin the sequence. It also costs slightly less logic on most tools, since a magnitude comparator against 9 can be simplified more aggressively than a full equality test. For an HDLBits exercise either is fine; for a design that has to be self-healing, `>=` is the better default. Knowing there's a choice — and what it buys — matters more than which one you pick.

- **`output [3:0] q` without `reg`** — same as Count15: HDLBits compiles as SystemVerilog and accepts it, strict Verilog-2001 does not, because a signal assigned inside an `always` block must be a variable. `output reg [3:0] q` is correct under both.

## Solution

See `count10.v`
