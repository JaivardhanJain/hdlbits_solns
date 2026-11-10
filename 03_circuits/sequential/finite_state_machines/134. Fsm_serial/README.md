# Fsm_serial

**HDLBits link:** https://hdlbits.01xz.net/wiki/Fsm_serial
**Category:** Circuits: Sequential (Finite State Machines)
**Difficulty:** ⭐⭐⭐

## Problem summary

A serial receiver for the framing a UART uses. The line sits at 1 when idle. A byte is sent as a **start bit** (0), then **8 data bits**, then a **stop bit** (1), one bit per clock. The FSM has to recognise correctly framed bytes and pulse `done` once for each. If the bit where the stop bit should be is a 0, the byte is discarded, and the receiver must wait for the line to go back to 1 before it looks for another start bit. Reset is synchronous. Capturing the data bits themselves comes next, in [[Fsm_serialdata]].

## Approach

Five states plus a counter. The FSM tracks *which part of the frame* we're in, and the counter tracks *how far through the data bits*:

| State | Meaning | Next on `in = 0` | Next on `in = 1` | `done` |
|:-----:|:--------|:----------------:|:----------------:|:------:|
| `IDLE` | line idle, waiting for a start bit | DATA | IDLE | 0 |
| `DATA` | receiving data bits (counter = bit index) | DATA, or STOP when `counter >= 7` | same | 0 |
| `STOP` | sampling the stop bit | INVALID | VALID | 0 |
| `VALID` | byte received correctly | DATA (back-to-back start bit) | IDLE | **1** |
| `INVALID` | bad stop bit, waiting for the line to idle | INVALID | IDLE | 0 |

Three design points:

- **Hybrid control: an FSM plus a counter.** Writing eight separate data-bit states (`D0` … `D7`) would also work and needs no counter, but the state count grows with the word width. One `DATA` state plus a counter scales: a 16-bit receiver changes one constant. This is the standard way to build "an FSM that waits *N* cycles".
- **`VALID` searches, like `IDLE`.** The `done` cycle is also the cycle in which the next frame's start bit can arrive, so `VALID` has `IDLE`'s transitions. It's the same reasoning as `got3` in [[Fsm_ps2]].
- **`INVALID` waits for a 1, not just for the next 0.** After a framing error the receiver has lost sync: the 0 it just saw might be a data bit of a garbled frame. Waiting until the line reads 1 before going back to `IDLE` is what the spec asks for, and it stops the receiver from treating a data bit as a start bit.

A trace of one good frame, a back-to-back frame with a bad stop bit, and the recovery. `counter` is its value *during* the cycle.

| Cycle | `in` | `state` | `counter` | `done` | `next_state` | What's happening |
|:-----:|:----:|:-------:|:---------:|:------:|:------------:|:-----------------|
| 1 | 1 | IDLE | 0 | 0 | IDLE | idle line |
| 2 | 0 | IDLE | 0 | 0 | DATA | start bit |
| 3 | d0 | DATA | 0 | 0 | DATA | data bit 0 |
| 4–9 | d1–d6 | DATA | 1–6 | 0 | DATA | data bits 1–6 |
| 10 | d7 | DATA | 7 | 0 | STOP | data bit 7: `counter >= 7` |
| 11 | 1 | STOP | 8 | 0 | VALID | good stop bit |
| 12 | 0 | VALID | 0 | **1** | DATA | `done`; *same cycle*: next start bit |
| 13–20 | d0–d7 | DATA | 0–7 | 0 | … → STOP | second frame's data |
| 21 | 0 | STOP | 8 | 0 | INVALID | bad stop bit: byte discarded |
| 22 | 0 | INVALID | 0 | 0 | INVALID | line still low: wait |
| 23 | 1 | INVALID | 0 | 0 | IDLE | line back at idle |
| 24 | 0 | IDLE | 0 | 0 | DATA | ready for a real start bit |

Eight cycles in `DATA`, with the counter at 0 through 7, are the eight data bits. The `counter >= 7` exit fires *during* bit 7, so the next cycle is the stop bit.

## Gotchas / things to watch for

- **The counter threshold must be traced, not guessed. Here it's right because of where the counter clears.** The counter is 0 during the first data bit because it's cleared in every non-`DATA` state, including the start-bit cycle, and it increments at the end of each `DATA` cycle. So the *k*th data bit sees `counter = k − 1`, and bit 8 sees 7, hence `>= 7`. Move the clear or the increment by one cycle (clear on entry to `DATA` instead of in the state before it, say) and the receiver reads 7 or 9 bits. It still passes some tests, depending on the data. It's the same off-by-one as the falling counter in Lemmings4: write out the cycle table and read the threshold off it.
- **`counter` uses blocking `=` in `always_ff`, next to `state <= ...` in the same block.** The third time in this chapter, after [[Fsm1s]] and [[Fsm_ps2data]]. Here it happens to work, because the only reader of `counter` is the combinational `always_comb`, which re-evaluates after the edge whichever assignment type was used. But it's a lint error, and it's a race waiting to happen: add a second clocked block that reads `counter` (the datapath in [[Fsm_serialdata]] is the obvious candidate), and whether it sees the old or new value depends on simulator scheduling. Registers get `<=`, every time: `counter <= counter + 1;`.
- **`logic [7:0] counter = 0;` is redundant, and isn't a reset.** The declaration initializer is a *power-up* value. On an FPGA it becomes the flop's configuration value. On an ASIC it's typically ignored, and some flows warn about it. The synchronous `reset` branch is what actually initializes `counter`, so the initializer adds nothing but a second, possibly conflicting, source of truth. (In SystemVerilog it also sits awkwardly next to `always_ff`'s single-driver rule.) Drop it.
- **Widths: an 8-bit counter to count to 8, and a 4-bit state for 5 states.** The counter never exceeds 8, so 4 bits are enough. 3 bits would do if it saturated or stopped at 7. Five states need 3 bits, not 4. Neither is a bug: the `default` covers the spare state codes, which is the [[Fsm3s]] lesson applied correctly. But sizing registers by the values they actually hold is a habit worth having, especially on the datapath.
- **The counter only runs when the FSM says so. That's the opposite choice to [[Fsm_ps2data]].** There, the shift register ran freely and the FSM only decided when its output was valid. Here, the counter is *controlled*: it clears outside `DATA`. It has to be, because its value drives a state transition, so it must start from a known value at the start of every frame. A free-running counter would carry over whatever it held from the previous frame. Rule of thumb: datapath registers whose values feed back into *control* need defined starting points, and pure data registers don't.
- **`STOP` samples one bit and trusts it.** A real UART receiver runs at 8× or 16× the bit rate and samples each bit near its middle, often taking a majority vote of three samples, because the transmitter's clock isn't the receiver's. HDLBits gives one clock per bit with perfect alignment. The FSM structure here is the right one, but a physical receiver also needs oversampling, a synchronizer on `in` (it's an asynchronous input: see the Edgedetect / Countslow notes on clocking from pins), and start-bit validation.

## Solution

See `fsm_serial.v`.
