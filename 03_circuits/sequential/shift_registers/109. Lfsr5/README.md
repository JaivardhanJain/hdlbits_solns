# Lfsr5

**HDLBits link:** https://hdlbits.01xz.net/wiki/Lfsr5
**Category:** Circuits: Sequential (Shift Registers)
**Difficulty:** ⭐⭐⭐

## Problem summary

A 5-bit maximal-length **Galois** LFSR with taps at positions 5 and 3, synchronously reset to `5'h1`. It's a shift register whose feedback comes from XOR gates rather than from outside: bit positions carrying a tap get the XOR of their neighbour and the output bit; every other position just shifts. With these taps the register visits all 31 non-zero states before repeating — `00001 → 10100 → 01010 → 00101 → …`.

## Approach

Every bit's next value is one short expression, so writing the five of them out is the most direct statement of the circuit:

```verilog
q[4]   <= q[0];             // feedback into the top bit
q[3]   <= q[4];             // plain shift
q[2]   <= q[3] ^ q[0];      // tapped bit: shift XOR feedback
q[1:0] <= q[2:1];           // plain shift, two bits at once
```

Two rules generate all four lines. Every bit shifts *down* one index, so `q[n] <= q[n+1]`. Then the Galois modification: the output bit `q[0]` is fed back into the top of the register (`q[4] <= q[0]`), and at each tap position that feedback bit is XORed into the bit arriving there (`q[2] <= q[3] ^ q[0]`). Positions without a tap are untouched by the feedback.

Working out where the taps land is the whole problem. HDLBits numbers bit positions 1…5, but Verilog indexes 4…0, so **position N is `q[N-1]`**: position 5 is `q[4]`, position 3 is `q[2]`. Every 5-bit Galois LFSR feeds `q[0]` back into `q[4]`, so the "position 5" tap is really just that feedback path; the only tap that changes anything about the structure here is position 3, which is why there's exactly one XOR gate in the design.

Checking the first transition by hand is worth the thirty seconds. From `00001`: `q[4]<=q[0]=1`, `q[3]<=q[4]=0`, `q[2]<=q[3]^q[0]=0^1=1`, `q[1:0]<=q[2:1]=00` → `10100`, which matches the sequence the problem gives. If the first step matches, the taps are in the right place.

An equivalent one-liner collapses all four assignments into a single 5-bit concatenation, in the style used throughout the rest of this chapter:

```verilog
else q <= {q[0], q[4], q[3] ^ q[0], q[2:1]};
```

Same hardware; the width check (1+1+1+2 = 5) is available at a glance, and there's only one assignment target to reason about. The per-bit form is arguably clearer for a first LFSR because each line reads as one flip-flop's input — but it does open the door to the mistakes below.

## Gotchas / things to watch for

- **All-zeros is a lock-up state, and that is the entire reason reset goes to `5'h1`.** Feed zeros into any XOR feedback network and you get zeros back: `0 ^ 0 = 0`, forever. An LFSR that reaches `00000` never leaves. That's why a maximal-length *n*-bit LFSR has 2ⁿ−1 states rather than 2ⁿ — the zero state is a separate, self-contained cycle of length one, not part of the sequence. Resetting to 0 out of habit (as every other register in this chapter does) produces a circuit that is permanently, silently dead: no `x`, no error, just a constant output. In a real design where the register might glitch into zero, you either prove it can't or add a lock-up-recovery gate that forces a non-zero state; the cost is one wide NOR.
- **Tap numbering is 1-indexed in the literature and 0-indexed in Verilog — writing `q[3]` for "tap 3" is the single most likely bug here.** Polynomial and tap-table notation (x⁵ + x³ + 1, "taps at 5 and 3") counts bit positions from 1, so position 3 is `q[2]`. Placing the XOR at `q[3]` instead compiles, runs, and produces a perfectly plausible-looking pseudorandom sequence — it just isn't maximal-length, so it cycles early and fails the grader somewhere past the point where you stopped watching the waveform. Always sanity-check against the given first few states rather than trusting the index.
- **Not every tap pair gives a maximal-length sequence — the taps encode a polynomial, and it has to be primitive.** x⁵+x³+1 is; x⁵+x⁴+1 isn't, and an LFSR built on it cycles through a small fraction of the state space. Taps aren't a tuning knob you can nudge; they come from a table. This is why "it produces random-looking bits" is not evidence that an LFSR is correct.
- **This is a Galois LFSR, not a Fibonacci one — they are different circuits with different state sequences.** Fibonacci form XORs several taps together and feeds the single result into the *input* end; Galois form (this one) feeds the output bit back to *several* positions, each with its own XOR. Both can be maximal-length with the corresponding polynomial, and both are called "the" LFSR in different textbooks. Galois is usually preferred in hardware because the XOR gates sit between adjacent flip-flops instead of chaining into a deep tree, so the critical path is one gate regardless of how many taps there are. Mixing the two structures — a Fibonacci-style feedback chain wired into Galois-style tap positions — produces a valid-looking circuit with the wrong sequence.
- **Non-blocking assignment is load-bearing here in a way it wasn't in the rest of this chapter.** [[Shift4]], [[Rotate100]] and [[Shift18]] each make one assignment per cycle, so `=` vs `<=` is mostly a matter of discipline. This block makes four, and they read each other. With blocking assignments, `q[4] = q[0];` executes first and *immediately* changes `q[4]`, so the very next line `q[3] = q[4];` picks up the value that was just written rather than the old one — the register corrupts itself in source order. Non-blocking assignment is what makes all five right-hand sides evaluate against the *current* state before any of them updates, which is precisely the behaviour of five flip-flops sharing a clock edge. This problem is the cleanest demonstration in the series of why the [[Dff]] rule exists.
- **Four separate assignments to slices of `q` in one block are legal because the slices are disjoint — nothing enforces that.** `q[4]`, `q[3]`, `q[2]`, and `q[1:0]` partition the register exactly, so each bit is assigned once. If two lines overlapped, Verilog would apply the last-executed-wins rule from [[Edgecapture]] per bit and silently drop the earlier assignment. Equally, if a line were *missing*, the un-assigned bit would simply hold its value — a self-feeding bit that quietly wrecks the sequence with no warning. The single-concatenation form makes both errors structurally impossible, which is the real argument for it.
- **The reset is synchronous, unlike [[Shift4]]'s.** Only `posedge clk` appears in the sensitivity list, so `reset` is sampled at the clock edge like any other input. That's what the spec asks for; the thing to notice is that the *same* `if (reset)` line means two different circuits depending on the sensitivity list alone, with no other syntactic clue.
- **`q` is declared `output [4:0] q` with no `reg`, and here that's HDLBits's own declaration.** It's assigned inside a procedural block, so strict Verilog-2001 requires `output reg [4:0] q`; HDLBits accepts the bare form because it compiles as SystemVerilog, where an output port is an implicit `logic`. Adding `reg` is portable and still passes the grader — see [[Dff8ar]]. Worth flagging because this is the first problem in the chapter where the *provided* declaration is the non-portable one, so copying the given header verbatim is what introduces the issue.
- **In practice, LFSRs are used as counters — but they don't count in order.** An LFSR needs no carry chain, so it's smaller and faster than a binary counter at the same width, which is why they show up as cheap cycle counters, PRBS/BIST pattern generators, scramblers, and the core of CRC logic. The catch is that state *k* has no simple relationship to the number *k*: you can use an LFSR to count 31 cycles, but not to address a memory in sequence or to display a value. Reaching for one as a drop-in counter replacement without checking that ordering doesn't matter is the classic misuse.

## Solution

See `lfsr5.v`.
