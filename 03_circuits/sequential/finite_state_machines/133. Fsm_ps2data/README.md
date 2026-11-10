# Fsm_ps2data

**HDLBits link:** https://hdlbits.01xz.net/wiki/Fsm_ps2data
**Category:** Circuits: Sequential (Finite State Machines)
**Difficulty:** ⭐⭐⭐

## Problem summary

[[Fsm_ps2]] found the boundaries of 3-byte PS/2 messages. This problem also *captures* the bytes. When `done` pulses, `out_bytes` must hold the whole message, with byte 1 in `[23:16]`, byte 2 in `[15:8]` and byte 3 in `[7:0]`. At any other time `out_bytes` is a don't-care.

It's the first problem in the series split into the two halves of almost every real digital block: a **control path** (the FSM, deciding *when*) and a **datapath** (registers, holding *what*).

## Approach

**Control path:** Fsm_ps2's four-state FSM, unchanged: search (`rst`), byte 1 received (`got1`), byte 2 (`got2`), byte 3 / done (`got3`, which searches again like `rst`). See [[Fsm_ps2]] for why `got3` has to check `in[3]`.

**Datapath:** a 24-bit shift register that takes in *every* byte, every cycle, whatever the FSM is doing: the old contents move up one byte and the new byte enters at the bottom. It's a sliding window over the last three bytes of the stream. The FSM never controls it. The trick is that `done` is only high in the cycle after byte 3, and in exactly that cycle the window holds bytes 1, 2, 3 in order. Byte 1 was shifted in first, so it has moved furthest up, to `[23:16]`.

A trace with message A = `2C 81 09` (`2C` has bit 3 set, as byte 1 must), followed immediately by byte 1 of message B (`0F`). `out` is the register's value *during* each cycle.

| Cycle | `in` | `state` | `out` | `done` | `out_bytes` |
|:-----:|:----:|:-------:|:-----:|:------:|:-----------:|
| 1 | 2C | rst | `xx xx xx` | 0 | 0 |
| 2 | 81 | got1 | `xx xx 2C` | 0 | 0 |
| 3 | 09 | got2 | `xx 2C 81` | 0 | 0 |
| 4 | 0F | got3 | `2C 81 09` | **1** | **`2C 81 09`** |
| 5 | 55 | got1 | `81 09 0F` | 0 | 0 |

Cycle 4 is the whole design. The window lines up with the message in precisely the cycle `done` is high. One cycle later it has already moved on to `81 09 0F`, half of A and the start of B, which is why the result is only valid while `done` is high. A consumer has to latch `out_bytes` on `done` if it wants to keep it.

## Gotchas / things to watch for

- **Blocking `=` in the datapath's `always_ff`, and here the statement order is what makes it correct.** `out[23:8] = out[15:0];` runs first and reads the *old* low bytes, then `out[7:0] = in;` overwrites the bottom byte. Swap the two lines and the first assignment writes `in` into `out[7:0]`. The shift then copies the *new* `in` up into `[15:8]`, so every incoming byte appears twice and the window holds only two distinct bytes. Non-blocking `<=` makes the order irrelevant, because every right-hand side reads the pre-edge value: that's the whole reason the [[Dff]] rule exists, and [[Lfsr5]] demonstrates it. It's also a lint error inside `always_ff`, which exists specifically to say "this is a flop". The idiomatic single line is `out <= {out[15:0], in};`, a concatenation with no ordering question at all. It's the same shape as the shift registers in [[Shift4]] and [[Exams_ece241_2013_q12]].
- **`===` in the `done` compare, again.** As in [[Fsm1]] and [[Fsm2]], before reset `state` is `x`, `state === got3` is a clean 0, and the uninitialized FSM shows up as a believable "not done". Here it has a second effect: `out_bytes = done ? out : 0` then reads a confident 0 as well, so the masking hides the `x` on *both* outputs. Use `==`.
- **The `out_bytes` masking is legal but unnecessary. The spec says don't-care when `done` is low.** `done ? out : 24'b0` costs 24 AND gates, and arguably makes the module *less* honest about when its output is meaningful: a consumer seeing zeros might take them as data. Since validity is signalled by `done`, the standard interface is to drive `out_bytes = out` and let the consumer qualify it with `done`. That's the valid/data pattern of essentially every bus, from a FIFO's `empty` flag to AXI's `TVALID`. Gating data with its own valid signal is something you do on purpose, for example to cut toggling on a long wire to save power, not by default.
- **The datapath has no reset, and that's the right call.** It holds `x` until three bytes have passed through. That doesn't matter, because `done` can't be high until the FSM has seen a byte 1 and two more cycles, by which time the window is full of real bytes. Leaving reset off datapath registers is standard practice: it saves routing and area, and only *control* state (the FSM) needs a known value. It's the opposite of [[Fsm3]], where the reset value of the *state* was what made the design work. It's also why masking `out_bytes` for cleanliness isn't needed.
- **A free-running datapath beats a controlled one here.** It's tempting to give the FSM a "capture" signal and load each byte into its own slot (`if (state == got1) byte2 <= in;` and so on). That works, but it adds 24 mux-and-enable paths and three decode terms, and it reintroduces the off-by-one risk of which state captures which byte. The always-shifting window needs neither, and it's correct by construction because the FSM's timing and the shift register's depth both equal 3. Watch for this pattern: sometimes the cheapest control is none at all.
- **A register called `out` next to a port called `out_bytes` invites confusion.** `out` is the internal window, `out_bytes` the qualified output, and HDLBits elsewhere uses `out` as a port name. Call the register `window` or `shift_reg` so it can't be mistaken for an output.
- **The good parts.** The state constants are *sized* (`2'b00` …), so they match the 2-bit `state` exactly, which is the fix [[Fsm3s]] needed. The `case` has a `default`. And every `if` in the combinational block has an `else`, so no latch.

## Solution

See `fsm_ps2data.v`.
