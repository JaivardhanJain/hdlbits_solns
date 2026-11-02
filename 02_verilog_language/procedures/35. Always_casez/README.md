# Always_casez

**HDLBits link:** https://hdlbits.01xz.net/wiki/Always_casez
**Category:** Verilog Language: Procedures
**Difficulty:** ⭐⭐

## Problem summary

Build an 8-bit priority encoder. `pos` is the index of the least significant bit of `in` that is 1. If `in` is all zeros, output 0.

## Approach

[Always_case2](../34.%20Always_case2/README.md) did a 4-bit encoder with one `case` item per input value. At 8 bits that's 256 items. `casez` fixes this: in a `casez` item, a `?` bit is a don't-care, so one item can cover many input values.

The output only depends on the lowest set bit, so everything above it can be `?`:

```verilog
casez (in)
    8'b10000000: pos = 3'b111;
    8'b?1000000: pos = 3'b110;
    ...
    8'b??????10: pos = 3'b001;
    8'b???????1: pos = 3'b000;
    default:     pos = 3'b000;
endcase
```

Each item reads as "bit N is 1, every bit below N is 0, and I don't care what's above". 9 items instead of 256, and the `default` catches `in = 0`.

`?` here is just another way to write `z`. `8'b???????1` and `8'bzzzzzzz1` are the same item, but `?` is the convention because it reads as "don't care" and doesn't look like a tri-state value.

## Gotchas / things I got wrong initially

- **"First" bit means least significant, not leftmost.** The spec asks for the lowest-indexed 1 bit, and the example `8'b10010000` should give 4. Reading the literal left to right, the way it's written, finds bit 7 first and gives 7, which is the highest set bit. Same trap as [Always_case2](../34.%20Always_case2/README.md), but easier to fall into here because the `casez` patterns are also written MSB-first. Tracing `8'b10010000` through this solution:

  | item | match? | why |
  |---|---|---|
  | `8'b10000000` | no | bit 4 is `1`, item wants `0` |
  | `8'b?1000000` | no | bit 6 is `0`, item wants `1` |
  | `8'b??100000` | no | bit 5 is `0`, item wants `1` |
  | `8'b???10000` | **yes** | bit 4 is `1`, bits 3:0 are `0`, bits 7:5 don't care → `pos = 4` |

- **The shorter version depends on item order.** HDLBits's own sample drops the trailing zeros and writes the items lowest bit first: `8'b???????1`, `8'b??????1?`, … `8'b1???????`. Those patterns overlap: `8'b10010000` matches both `8'b???1????` and `8'b1???????`. It works only because `case` takes the first match. Move `8'b1???????` to the top and the same input gives 7, with no warning. This solution pins every bit below the target to 0, so each input matches exactly one item and the order doesn't matter. Synthesis can treat non-overlapping items as parallel logic, and lint has nothing to flag.

- **`casez` also ignores `z` on the input, not just in the items.** A `z` bit in `in` matches anything, the same way `?` does in an item. If `in` is left undriven in simulation (all `z`), the first item matches and `pos` shows 7 instead of `x`, which hides the bug. `casex` is worse: it treats `x` as a don't-care too, so uninitialized signals disappear as well. Use `casez` with `?` and avoid `casex`.

## Solution

See `always_casez.v`
