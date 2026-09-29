# Always_case

**HDLBits link:** https://hdlbits.01xz.net/wiki/Always_case
**Category:** Verilog Language: Procedures
**Difficulty:** ⭐

## Problem summary

Build a 6-to-1 multiplexer of 4-bit inputs using a `case` statement. When `sel` is 0–5, output the matching `dataN`. When `sel` is 6 or 7, output 0.

## Approach

A `case` statement compares `sel` against each item in turn and runs the statement for the first one that matches:

```verilog
always @(*) begin
    case (sel)
        3'b000:  out = data0;
        ...
        3'b101:  out = data5;
        default: out = 4'b0000;
    endcase
end
```

Each item is one row of the mux's truth table, so the code reads like the spec. It's the natural way to write a mux with more than two inputs. A chain of `if`/`else if` would work too, but it implies a priority order that a mux doesn't have, and it gets long. A nested `?:` gets unreadable quickly.

A 3-bit `sel` has 8 possible values and only 6 have data inputs. The `default` covers the other two (6 and 7) and outputs 0, as the spec asks.

A few syntax points that differ from C's `switch`:

- There's no `break` and no fall-through. Only the matching item's statement runs.
- Each item runs exactly **one** statement. For more than one, wrap them in `begin` / `end`.
- Duplicate or overlapping items are legal. The first match wins, and the later ones are silently ignored.

## Gotchas / things I got wrong initially

- **The `default` is what keeps this combinational.** Remove it and `sel` = 6 or 7 matches no item, so nothing assigns `out`. It keeps its old value, which means a latch. That's the same failure as the missing `else` in [Always_if2](../32.%20Always_if2/README.md), and it's the most common way latches sneak into real designs. Even if every value is listed (8 items for a 3-bit `sel`), keep a `default`. In simulation, `sel` can also be `x` or `z`, and those match no numbered item either.

- **My first draft had `default: out = 3'b000;`.** That's a 3-bit constant assigned to a 4-bit output. It happens to work, because Verilog zero-extends it to `4'b0000`. But the width doesn't match the output, and with a non-zero value (`3'b111` padded to `4'b0111`, not `4'b1111`) it would silently give the wrong answer. It's the same sized-literal lesson from Step One. I changed it to `4'b0000`. `4'd0` or plain `0` would also be fine.

- **An unmatched `x` on `sel` goes to `default`.** In simulation, if `sel` is `x`, no item matches it, so the `default` runs and `out` shows a clean 0. That can hide the fact that `sel` was never driven. Some teams put `out = 4'bx;` in the default when the unused values can never happen, which shows problems in simulation and lets synthesis pick the cheapest logic. Here the spec says 0, so 0 it is.

- **Duplicate items are silently ignored.** If two items have the same value (for example, after copy-pasting a line and forgetting to change it), only the first ever runs and the second input is never selected. No compile error. Many lint tools warn about it, so pay attention to that warning.

- **Plain `case` is the right choice here, not `casex` or `casez`.** Those treat some bits as "don't care", which is useful for priority encoders (coming up in the next problems). For a plain mux with every bit specified, `case` is the correct and safest form.

- **Multiple outputs need an assignment in every item.** This block only drives `out`, so one assignment per item is enough. If a `case` drives several outputs, an item that sets one but forgets another infers a latch on the forgotten one. The default-assignment idiom from [Always_if](../31.%20Always_if/README.md) (assign every output once at the top of the block, then override inside the `case`) prevents that.

## Solution

See `always_case.v`
