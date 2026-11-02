# Always_case2

**HDLBits link:** https://hdlbits.01xz.net/wiki/Always_case2
**Category:** Verilog Language: Procedures
**Difficulty:** ⭐⭐

## Problem summary

Build a 4-bit priority encoder. `pos` is the index of the lowest-numbered bit of `in` that is 1. If `in` is all zeros, output 0.

## Approach

A 4-bit input has 16 possible values, so the brute-force way is a 16-row `case`: one item per input value, each assigning the right `pos`.

```verilog
always @(*) begin
    case (in)
        4'h0: pos = 2'h0;
        4'h1: pos = 2'h0;
        4'h2: pos = 2'h1;
        ...
        4'hf: pos = 2'h0;
        default: pos = 2'b0;
    endcase
end
```

To fill in a row, write the value in binary and find the lowest 1:

| `in` | binary | lowest set bit | `pos` |
|---|---|---|---|
| `4'h6` | `0110` | bit 1 | 1 |
| `4'h8` | `1000` | bit 3 | 3 |
| `4'hc` | `1100` | bit 2 | 2 |
| `4'hf` | `1111` | bit 0 | 0 |

Every odd value has bit 0 set, so half the table is `pos = 0`. Hex literals (`4'hb`) keep the items short compared with binary (`4'b1011`).

This works, but it doesn't scale: an 8-bit encoder would need 256 rows. The next problem ([Always_casez](https://hdlbits.01xz.net/wiki/Always_casez)) shows the compact way.

## Gotchas / things I got wrong initially

- **You can't use `x` as a "don't care" in a `case` item.** Looking at the table, it's tempting to collapse 16 rows into 4:

  ```verilog
  case (in)
      4'bxxx1: pos = 2'd0;
      4'bxx10: pos = 2'd1;
      4'bx100: pos = 2'd2;
      4'b1000: pos = 2'd3;
      default: pos = 2'd0;
  endcase
  ```

  This compiles with no error, and it's wrong. A plain `case` compares every bit exactly, and `x` is one of the values it compares against. So `4'bxxx1` doesn't mean "anything ending in 1". It means "the top three bits are literally `x`", which a real input never is.

  Trace `in = 4'b0110` (expected `pos = 1`):

  | item | match? | why |
  |---|---|---|
  | `4'bxxx1` | no | bit 3 is `0`, item wants `x` |
  | `4'bxx10` | no | bit 3 is `0`, item wants `x` |
  | `4'bx100` | no | bit 3 is `0`, item wants `x` |
  | `4'b1000` | no | bit 3 is `0`, item wants `1` |
  | `default` | yes | `pos = 0` |

  The only item that can ever match is `4'b1000`. Everything else falls to the `default`, so the circuit is wrong for `in` = 2, 6, 10, 14 (should be 1) and 4, 12 (should be 2). Synthesis tools treat the `x` items as never matching, usually with a warning.

  Note this is about `x` in a case *item*. Assigning `x` on the right-hand side (the `out = 4'bx` default mentioned in [Always_case](../33.%20Always_case/README.md)) is a different thing and is fine. Wildcard matching needs `casez` with `?`, which is the next problem. With plain `case`, all 16 rows have to be written out.

- **"First" 1 bit means the lowest-numbered bit, not the leftmost.** The problem's example is `8'b10010000` giving 4, not 7. Reading the vector left to right, as it's written, gives the highest set bit instead. For `4'b0110` that's 2 instead of 1.

- **The `default` isn't needed to avoid a latch here, but keep it.** All 16 values are listed, so every real input assigns `pos`. In simulation `in` can still contain `x` or `z`, which matches none of the 16 items, and without a `default` `pos` would hold its old value. Same reasoning as [Always_case](../33.%20Always_case/README.md).

- **`pos = 0` is ambiguous.** It's the output for `in = 4'b0001` and also for `in = 4'b0000`. The spec asks for that, but a priority encoder in a real design normally has a separate `valid` output so the consumer can tell "bit 0 is set" from "nothing is set".

## Solution

See `always_case2.v`
