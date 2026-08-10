# Edgecapture

**HDLBits link:** https://hdlbits.01xz.net/wiki/edgecapture
**Category:** Circuits: Sequential (Latches and Flip-flops)
**Difficulty:** ⭐⭐⭐⭐

## Problem summary

For each of 32 bits, detect a 1→0 transition (the opposite direction from [[Edgedetect]]) and **latch** it: once a bit sees a falling edge, its output stays 1 — regardless of what `in` does afterward — until a synchronous `reset` clears the whole output back to 0. If a falling edge and a `reset` land on the same cycle, `reset` wins.

## Approach

Two things are happening at once here, and it's worth separating them: *detecting* an edge (the same shadow-register trick as [[Edgedetect]]/[[Edgedetect2]]) and *remembering* that it happened (new to this problem).

```verilog
always @ (posedge clk) begin
    in_prev <= in;
    if (reset)
        out <= 32'b0;
    else
        out <= out | (~in & in_prev);
end
```

`~in & in_prev` is this cycle's edge detection — 1 wherever a bit was 1 last cycle and is 0 now, the mirror image of [[Edgedetect]]'s `in & ~d_last`. What makes this problem different is `out <= out | (...)` instead of `out <= (...)`: each cycle's output is the *previous* output OR'd with any newly-detected edges, so once a bit goes high it can never go low again on its own — only `reset` can clear it. That's the "capture" behaviour: functionally, each output bit is acting like an SR latch, set by its own edge detector and reset by the shared `reset` line, exactly as the problem statement says.

`reset`'s priority falls straight out of the `if`/`else` structure: when `reset` is high, `out <= 32'b0` is the *only* thing that executes for `out` that cycle — the OR-accumulation in the `else` branch doesn't run at all, so even a real edge detected on the same cycle is discarded in favour of the reset. That's "reset has precedence," not something requiring extra logic to arbitrate.

## Gotchas / things to watch for

- **`in_prev` must keep updating every cycle, including cycles where `reset` is asserted — resetting it would be the actual bug.** It's tempting to reset `in_prev` alongside `out` (there's a commented-out `//in_prev <= 32'b0;` in early drafts of this exact circuit, showing the idea being tried and then backed out). Don't: `out` and `in_prev` are reset by two completely different requirements. The spec says *`out`* must clear on reset — it says nothing about `in_prev`, which exists purely to track `in`'s recent history so the *next* cycle's edge detection is accurate. Forcing `in_prev` to 0 during reset would make the cycle right after reset ends compare `in` against a fake "0" history instead of `in`'s real prior value, corrupting edge detection right at the reset boundary — the one place you'd most want it to work correctly. When a circuit has both an output that must reset and an internal bookkeeping register that shouldn't, resetting them together "for consistency" is the mistake, not the safe default.
- **Two non-blocking assignments to the same variable in one always block is legal, but only the last one executed actually sticks — and that's easy to get backwards.** A version of this circuit that assigns `in_prev <= in;` once unconditionally at the top of the block *and* again inside the `else` branch is not a bug (both assignments compute the identical value, `in`, so which one "wins" doesn't matter) — but it's exactly the kind of redundancy that becomes a real bug the moment someone edits only one of the two copies. Verilog resolves multiple non-blocking assignments to the same register within one always-block invocation by letting the *last-executed* one determine the final value, which is the opposite of what "first assignment wins" intuition might suggest. The clean version above assigns `in_prev` exactly once, unconditionally, at the top — there's nothing left to accidentally desynchronize.
- **`~in & in_prev` — order and direction of NOT matter, and it's the reverse of the last two problems.** [[Edgedetect]] used `in & ~d_last` (0→1: currently high, previously low). This problem wants 1→0: currently low, previously high — `~in & in_prev`. It's easy to type the [[Edgedetect]] formula from memory and only skim past which operand gets the `~`; re-derive from the truth condition each time rather than pattern-matching to a previous problem's code.
- **This is a sticky/latching accumulator, not a stateless combinational check — reading the waveform wrong is easy.** Unlike [[Edgedetect]]/[[Edgedetect2]], where each output pulse is exactly one cycle wide, `out` here stays high indefinitely after a capture. A waveform where `out[i]` is 1 for 40 cycles doesn't mean 40 edges happened — it means *one* edge happened at some point since the last reset. Don't read persistence as repetition.
- **`out` needs `output reg`.** Assigned inside a clocked always block — same note as every sequential problem in this chapter; see [[Dff8ar]] for why HDLBits's bare `output [31:0] out` compiles anyway.

## Solution

See `edgecapture.v`.
