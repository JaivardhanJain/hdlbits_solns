# Rotate100

**HDLBits link:** https://hdlbits.01xz.net/wiki/Rotate100
**Category:** Circuits: Sequential (Shift Registers)
**Difficulty:** ⭐⭐

## Problem summary

A 100-bit rotator with a synchronous load. Unlike the shift register in [[Shift4]], nothing is discarded and nothing is shifted in: the bit that falls off one end reappears at the other. `ena` is a 2-bit *code*, not two independent enables — `2'b01` rotates right, `2'b10` rotates left, and both `2'b00` and `2'b11` mean hold. `load` overrides everything and captures `data`.

## Approach

Same skeleton as [[Shift4]] — one clocked block, a priority chain with `load` first, and no `else` so the register holds — with the rotate expressed as a concatenation:

```verilog
q <= {q[0],    q[99:1]};   // rotate right
q <= {q[98:0], q[99]};     // rotate left
```

Read each one as *"the bit that leaves, re-attached at the far end."* Rotating right moves every bit toward index 0, so `q[0]` is the one with nowhere to go; the part select `q[99:1]` carries the other 99 bits down one position, and `q[0]` is pasted back on at the MSB end. Rotating left is the same sentence with both ends swapped: `q[99]` is evicted, `q[98:0]` moves up one, and the evicted bit lands at index 0.

The widths are the check that this is right: 1 + 99 = 100 on both lines, exactly the width of `q`. A rotation is *width-preserving by construction*, which is the structural difference between a rotator and a shifter, and it's why concatenation is mandatory here rather than optional.

Worth noticing what this costs in hardware: nothing. The rotate itself is pure wiring — bit *i* of the register is fed from bit *i+1*, or *i−1*, or `data[i]`, or itself. The only logic synthesized is a 100-bit-wide 4-to-1 mux in front of the flops. There's no adder, no shifter tree, no carry chain.

## Gotchas / things to watch for

- **`ena` is a 2-bit encoding, not two independent enable bits — decoding it bit-by-bit silently breaks the `2'b11` case.** The natural-looking version is:
  ```verilog
  else if (ena[0])  q <= {q[0], q[99:1]};    // WRONG
  else if (ena[1])  q <= {q[98:0], q[99]};
  ```
  It gets `2'b01` and `2'b10` right and passes a casual read, but on `2'b11` the first branch matches and the register rotates right, where the spec demands *hold*. The `else if` chain quietly converted "invalid code" into "right wins." Compare against the full encoding table, not just the two rows you care about — the two don't-rotate codes are as much a part of the spec as the two active ones. `case (ena)` with all four values listed makes the omission impossible to write in the first place, and is the more idiomatic way to decode a mode field:
  ```verilog
  else case (ena)
      2'b01:   q <= {q[0], q[99:1]};
      2'b10:   q <= {q[98:0], q[99]};
      default: q <= q;
  endcase
  ```
- **An over-wide concatenation truncates from the MSB end, silently.** Type `{q[0], q[99:0]}` instead of `{q[0], q[99:1]}` — one character — and you have a 101-bit RHS going into a 100-bit register. Verilog doesn't complain; truncation happens at the **MSB** end, so the wrap bit you just carefully added is precisely the one thrown away — the surviving 100 bits are `q[99:0]`, unchanged, and your "rotate right" is a very expensive way of doing nothing. This is the same implicit-resizing rule from [[Step One]] that fills zeros for you in [[Shift4]], running in the other direction, and it's much more dangerous here: in a shifter the resize *is* the intended behaviour, in a rotator it destroys it. Add the widths of every concatenation you write and check the sum against the target.
- **The two rotate lines are near-anagrams of each other, and swapping them produces a working circuit that rotates the wrong way.** `{q[0], q[99:1]}` vs `{q[98:0], q[99]}` differ only in where the single bit sits and which slice accompanies it. Nothing about a mixed-up pair is a compile error or a width error — the testbench just reports the wrong direction. Derive each from the sentence ("which bit has nowhere to go? put it at the other end") rather than pattern-matching the shape; and note that the correct *right* rotate puts a **single** bit on the **left**, which feels backwards until you say it out loud.
- **`{q[99], q[99:1]}` is a different circuit entirely — that's an arithmetic right shift, not a rotate.** Replicating the MSB instead of recirculating the LSB is the sign-extending `>>>` behaviour. It's a one-index typo away from the correct line and is a *plausible* circuit, so it won't look wrong when you re-read it.
- **This rotator has no reset, and unlike a shifter it can never flush itself clean.** All 100 flops power up as `x`, and every rotate mode feeds `q` back into itself — so an `x` anywhere in the register circulates forever. [[Shift4]] recovers on its own after four enabled cycles because it shifts in known zeros; here `load` is the *only* path that ever puts a defined value into the register. If a simulation shows red `x` everywhere and no amount of clocking clears it, that's not a bug in your rotate, it's an uninitialized register that has never been loaded. It also means a real design built this way must guarantee a load before the contents are used — worth stating explicitly in the module's comments, or fixing with a reset like [[Shift4]]'s.
- **`2'h1` and `2'h2` are legal but say the wrong thing.** Hex on a 2-bit mode field forces the reader to convert back to binary before they can compare against the spec's `2'b01`/`2'b10` table, and hex digits carry 4 bits of implied width against a 2-bit port. `2'b01` costs nothing and matches the encoding as written. (The solution file keeps the original form; the point is that literal *base* is part of how readable a decode is.)
- **Missing `else` means hold** — same as [[Shift4]]. In a clocked block an unassigned register keeps its value, which is exactly the `2'b00`/`2'b11` behaviour the spec asks for; there's no inferred latch to worry about.
- **`q` needs `output reg`** because it's assigned procedurally — see [[Dff8ar]] for why HDLBits's own bare `output [99:0] q` compiles anyway.

## Solution

See `rotate100.v`.
