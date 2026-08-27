# Shift4

**HDLBits link:** https://hdlbits.01xz.net/wiki/Shift4
**Category:** Circuits: Sequential (Shift Registers)
**Difficulty:** ⭐⭐

## Problem summary

A 4-bit right-shift register with three control inputs. `areset` clears `q` to 0 asynchronously; `load` captures `data` into `q`; `ena` shifts `q` one position toward the LSB, dropping `q[0]` off the end and pulling a 0 into `q[3]`. If nothing is asserted, `q` holds. `load` outranks `ena` when both are high.

## Approach

The whole circuit is one clocked block with a priority chain, and the interesting part is that each of the four behaviours in the spec maps onto exactly one syntactic feature:

```verilog
always @(posedge clk, posedge areset) begin
    if (areset)         q <= 0;
    else if (load)      q <= data;
    else if (ena)       q <= q[3:1];
end
```

- **Asynchronous reset** → `posedge areset` in the sensitivity list, checked first inside the block. The block wakes on a reset edge with no clock in sight, which is precisely what "asynchronous" means (same pattern as [[Dff8ar]]).
- **`load` beats `ena`** → the `else if` chain. Priority isn't extra logic here; it's the ordering of the branches.
- **Shift** → a part select. `q[3:1]` is "the top three bits", and assigning them to a 4-bit target slides each one down an index: old `q[3]`→`q[2]`, `q[2]`→`q[1]`, `q[1]`→`q[0]`. Old `q[0]` isn't in the RHS at all, so it's gone.
- **Idle** → no `else`. The chain simply ends, so on a cycle where nothing is asserted `q` gets no assignment and the flip-flops keep their value.

The zero that arrives at `q[3]` is never written explicitly. `q[3:1]` is a 3-bit value being assigned to a 4-bit register, so Verilog zero-extends it on the left — the shifted-in 0 is a side effect of the width rule. That works, but see the first gotcha.

## Gotchas / things to watch for

- **The shifted-in zero comes from implicit zero-extension, not from anything you wrote — say it out loud instead.** `q <= q[3:1];` assigns a 3-bit RHS to a 4-bit LHS, and the width-matching rule from [[Step One]] (the same rule behind `1` vs `1'b1`) pads the missing MSB with 0. The circuit is correct, but it's correct *by accident of a language rule* rather than by intent, and a reader has to reconstruct the argument to convince themselves `q[3]` really goes to 0 and not to `x` or to old `q[3]`. The explicit form is the same hardware and reads as a statement of intent:
  ```verilog
  q <= {1'b0, q[3:1]};   // fill bit is visible in the source
  ```
  This also matters the moment the fill bit stops being 0 — an arithmetic right shift, a rotate (`{q[0], q[3:1]}`), or a serial-in shift register (`{sin, q[3:1]}`) are all one token away from this line, and only the concatenation form makes that token editable. Relying on implicit resizing is also what makes the *wrong* shifts below compile silently.
- **`q <= q[2:0];` is not the opposite shift — it isn't a shift at all.** It looks like the mirror image of the correct line, and it compiles cleanly, but it takes the bottom three bits and puts them back in the bottom three positions, only clearing `q[3]`. The bits don't move. A left shift is `q <= {q[2:0], 1'b0};` — you have to concatenate the incoming bit on the *right*, because there is no width rule that pads a vector at the LSB end. That asymmetry is exactly why right shifts written as a bare part select are a trap: the sloppy version happens to work in one direction and silently does nothing in the other.
- **A missing `else` in a *clocked* block means "hold", not "inferred latch".** The rule drilled in the combinational chapters — an incomplete `if` infers a latch — applies to combinational always blocks, where an unassigned output has to remember something it shouldn't. Inside `always @(posedge clk)`, `q` is already a flip-flop; leaving it unassigned on some cycles just means the flop keeps its value, which synthesizes as a clock-enable on the register. Adding `else q <= q;` is legal and produces identical hardware, but it's noise. The genuine mistake is the reverse reflex: "incomplete if is bad" leading someone to add an `else q <= 0;`, which turns the idle mode into a clear and breaks the spec.
- **`else if` encodes priority; separate `if` statements encode the *opposite* priority.** Writing three independent `if` statements instead of a chain is legal in a clocked block — multiple non-blocking assignments to `q` resolve last-executed-wins (the same rule flagged in [[Edgecapture]]) — so `if (load) q <= data; if (ena) q <= q[3:1];` would silently give **`ena`** priority, the reverse of what the spec asks for. Nothing warns you. And within a chain, swapping the two branches is a one-line change that flips the priority with no width or type error to catch it.
- **`areset` must be in the sensitivity list *and* checked first — and this pattern only works for reset-like signals.** Dropping `posedge areset` from the list leaves the code compiling as a *synchronous* reset, which passes casual eyeballing and fails the moment the testbench asserts reset between clock edges. Conversely, you can't extend the trick: adding `posedge load` to the list doesn't create an asynchronous load, it creates a nonsense block that synthesis will reject, because the async-reset template is a specific pattern tools pattern-match against — one clock edge, plus reset edges, with the reset condition tested first and assigning a constant. See [[Dff8ar]] for the same template on a plain register.
- **"Right shift" is about bit significance, not about which way the number gets printed.** `q[0]` shifts *out* and `q[3]` receives the 0, so the value moves toward the LSB — a right shift is a divide-by-two. It's easy to look at `q[3:1]` sliding into `q[2:0]`, see indices decreasing, and talk yourself into calling it a left shift. Anchor on the MSB-first declaration convention from [[Vector0]]: in `[3:0]`, "right" means toward index 0.
- **`q` needs `output reg`** because it's assigned inside a procedural block — same note as every problem in the sequential chapters; [[Dff8ar]] covers why HDLBits's bare `output [3:0] q` compiles anyway under its SystemVerilog front end.
- **In production, an asynchronous reset is usually asserted asynchronously but *de-asserted* synchronously.** HDLBits drives `areset` directly and that's fine for the grader, but a raw async release can violate the flip-flop's recovery/removal timing and leave different flops in the register coming out of reset on different cycles. The standard fix is a two-flop reset synchronizer feeding the `areset` port — worth knowing about now, since every async-reset register from here on inherits the issue.

## Solution

See `shift4.v`.
