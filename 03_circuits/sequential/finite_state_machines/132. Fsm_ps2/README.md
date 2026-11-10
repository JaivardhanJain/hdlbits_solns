# Fsm_ps2

**HDLBits link:** https://hdlbits.01xz.net/wiki/Fsm_ps2
**Category:** Circuits: Sequential (Finite State Machines)
**Difficulty:** ⭐⭐⭐

## Problem summary

A PS/2 mouse sends 3-byte messages back to back in a continuous byte stream, with no start or end marker. The only framing information is that the *first* byte of every message has bit 3 set. Bit 3 of the other two bytes can be anything. The FSM receives one byte per clock and has to find message boundaries: throw bytes away until one has `in[3] = 1`, treat it as byte 1, take the next two as bytes 2 and 3, and pulse `done` for the single cycle right after byte 3. Reset is synchronous.

This is the first FSM in the series that does a real-world job: **framing**, i.e. recovering message boundaries from a stream. [[Fsm_ps2data]] adds the datapath that captures the bytes.

## Approach

Four states. Only `in[3]` matters to the FSM. The other seven bits are payload, irrelevant to framing.

| State | Meaning | `in[3] = 0` | `in[3] = 1` | `done` |
|:-----:|:--------|:-----------:|:-----------:|:------:|
| `RST`  | searching for byte 1 | RST | REQ1 | 0 |
| `REQ1` | got byte 1 | REQ2 | REQ2 | 0 |
| `REQ2` | got byte 2 | REQ3 | REQ3 | 0 |
| `REQ3` | got byte 3: message complete | RST | REQ1 | **1** |

Two features of the table carry the whole problem:

- **`REQ1` and `REQ2` ignore `in[3]`.** Once byte 1 is found, the next two bytes belong to the message whatever their bit 3 says. The FSM *counts*; it isn't looking for patterns during a message.
- **`REQ3` behaves like `RST`.** The cycle in which `done` is high is also the cycle in which the next byte arrives, and that byte might be the next message's byte 1. So `REQ3`'s transitions are copied from `RST`'s.

HDLBits's hint says why three states aren't enough. `done` must be high for the cycle *after* byte 3, and a Moore output needs its own state for that cycle. `REQ3` is that state, doubling as the search state.

A trace with a discarded byte, a message whose byte 2 happens to have bit 3 set, a back-to-back message, and a return to searching. Each row is one clock cycle: the byte present during that cycle, the state during it, and the state at the next edge.

| Cycle | `in[3]` | `state` | `done` | `next_state` | What's happening |
|:-----:|:-------:|:-------:|:------:|:------------:|:-----------------|
| 1 | 0 | RST | 0 | RST | junk byte, discarded |
| 2 | 1 | RST | 0 | REQ1 | byte 1 of message A |
| 3 | 1 | REQ1 | 0 | REQ2 | byte 2 of A: its bit 3 is ignored |
| 4 | 0 | REQ2 | 0 | REQ3 | byte 3 of A |
| 5 | 1 | REQ3 | **1** | REQ1 | `done` for A; *same cycle*: byte 1 of B |
| 6 | 0 | REQ1 | 0 | REQ2 | byte 2 of B |
| 7 | 0 | REQ2 | 0 | REQ3 | byte 3 of B |
| 8 | 0 | REQ3 | **1** | RST | `done` for B; this byte isn't byte 1 |
| 9 | 0 | RST | 0 | RST | searching |

Cycle 5 is the case most first attempts get wrong.

## Gotchas / things to watch for

- **`REQ3` must check `in[3]`, or back-to-back messages lose a byte.** The tempting version is `REQ3: next_state = RST;`: message done, go back to searching. But in cycle 5 above, byte 1 of message B is *already on the bus* while `done` is high for message A. Sending the FSM to `RST` throws that byte away. Then `RST` sees byte 2 of B, which may or may not have bit 3 set. If it doesn't, the FSM skips message B entirely. If it does, it frames B's byte 2 as a byte 1, and every later message is misaligned. A mouse streaming movement reports sends messages back to back all the time, so this isn't an edge case. Any state that asserts a "finished" output *and* coincides with new input has to handle that input. Here that means `REQ3` inherits `RST`'s transitions.
- **Don't check `in[3]` on bytes 2 and 3. It's a counter, not a pattern detector.** If the FSM re-synced whenever it saw bit 3 = 1, i.e. `REQ1: next_state = in[3] ? REQ1 : REQ2;`, then any message whose byte 2 or 3 had bit 3 set would be truncated and re-started from the middle (cycle 3 in the trace). HDLBits states it directly: this is not a "1xx" sequence recognizer, and messages don't overlap. Bit 3 is only meaningful at a position where a byte 1 is *expected*.
- **Framing from a single bit can lock onto the wrong boundary, and nothing here would notice.** If the FSM comes out of reset mid-message, and that message's byte 2 or 3 happens to have bit 3 set, the FSM takes it as a byte 1. From then on it reports misaligned messages, which can continue indefinitely if the payload keeps cooperating. That's inherent to the protocol rather than a bug in this module: the real PS/2 mouse protocol adds parity and a host-side sanity check of each packet. But it's the general weakness of any framing scheme with a one-bit marker. Real link layers use longer sync patterns (HDLC flags, Ethernet preambles, 8b/10b commas), escape any appearance of them in the data, or add checksums. [[Fsm_hdlc]] shows the escaping approach.
- **`RST` is a misleading name for the search state.** It's the reset target, but it's also where the FSM sits during every idle gap, and it's equivalent to `REQ3` apart from `done`. Name states for what they mean, not how they're entered: `SEARCH`/`BYTE1`/`BYTE2`/`DONE`, for example. That also makes the cycle-5 behaviour read naturally: `DONE` transitions like `SEARCH`. The `REQ` prefix doesn't describe anything either: these states mean "byte *n* received", not "request".
- **The `case` is full, because 2 bits hold exactly 4 states, so no latch.** That's the situation [[Fsm3s]] got wrong, where the register was wider than the encoding needed. Here the width is right. A `default: next_state = RST;` still costs nothing and survives a fifth state being added later. Sized `localparam [1:0]` constants would tie the parameter widths to `state`'s.
- **`done` is a Moore output, so it's registered and glitch-free, but one cycle "late".** It goes high the cycle *after* byte 3, which is exactly what the spec asks for. A Mealy version (`done = (state == REQ2)`, i.e. "the byte arriving now is byte 3") would assert a cycle earlier, combinationally. That's off by one against this spec, and it ties `done`'s timing to the input. In [[Fsm_ps2data]] this choice also decides when the captured bytes are valid.
- **Unused input bits are expected.** `in[7:0]` arrives but only `in[3]` is read, so synthesis will warn that `in[7:4]` and `in[2:0]` are unused. That's a correct warning here, since the payload is for the datapath in the next problem. In a real design you'd silence it deliberately (a lint waiver or a comment), not by tying the bits into some dummy logic.

## Solution

See `fsm_ps2.v`.
