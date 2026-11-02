# Bcdadd100

**HDLBits link:** https://hdlbits.01xz.net/wiki/Bcdadd100
**Category:** Verilog Language: More Verilog Features
**Difficulty:** ⭐⭐⭐

## Problem summary

HDLBits provides `bcd_fadd`, a one-digit BCD adder (two 4-bit BCD digits plus a carry-in, giving a 4-bit BCD sum digit and a carry-out). Instantiate 100 of them to add two 100-digit BCD numbers, each packed into a 400-bit vector, plus `cin`. Output the 400-bit sum and the final carry-out.

## Approach

This is [Adder100i](../42.%20Adder100i/README.md) with a 4-bit digit in place of each bit: a ripple-carry chain of 100 cells, with each cell's carry-out feeding the next one's carry-in. Digit `d` sits in bits `[4d+3 : 4d]` of `a`, `b` and `sum`:

| digit | bits | carry in | carry out |
|---|---|---|---|
| 0 | `[3:0]` | `cin` | `carry[0]` |
| 1 | `[7:4]` | `carry[0]` | `carry[1]` |
| 2 | `[11:8]` | `carry[1]` | `carry[2]` |
| … | … | … | … |
| 99 | `[399:396]` | `carry[98]` | `carry[99]` → `cout` |

As in Adder100i, digit 0 is the irregular one because its carry comes from `cin`. This solution instantiates digit 0 by hand and uses a generate loop for digits 1–99. The loop variable `i` counts in *bits*, stepping by 4 (`i = 4, 8, …, 396`), so `i/4` is the digit number:

| `i` | digit `i/4` | `a[i +: 4]` | `.cin` | `.cout` |
|---|---|---|---|---|
| 4 | 1 | `a[7:4]` | `carry[0]` | `carry[1]` |
| 8 | 2 | `a[11:8]` | `carry[1]` | `carry[2]` |
| 396 | 99 | `a[399:396]` | `carry[98]` | `carry[99]` |

### Indexed part-selects: `+:`

`a[i +: 4]` means "4 bits starting at bit `i` and going up", i.e. `a[i+3 : i]`. There's also `-:`, which goes down: `a[i -: 4]` is `a[i : i-3]`. The width after `+:` must be a constant; the start can be a variable.

This matters most in procedural code. Inside an `always` block with a variable `i`, `a[i+3 : i]` is illegal, because both ends of a plain range must be constants even if their difference is fixed. `a[i +: 4]` is legal because only the start varies. In a generate loop `i` is a genvar, which counts as a constant, so either form works there, but `+:` states the intent ("a 4-bit slice at offset i") directly and is the standard way to slice packed fields.

## Gotchas / things I got wrong initially

- **You can't add packed BCD with `+`.** It's tempting to skip the instances and write `assign {cout, sum} = a + b + cin;`. That does a binary add of the 400-bit vectors and gives the wrong answer as soon as any digit sum passes 9. With single digits `9 + 1`: binary gives `4'b1010` (hex A, which isn't a BCD digit) with no carry. The BCD answer is digit `0` with a carry of 1 into the next digit. That decimal correction (add 6 when the digit sum exceeds 9) is what `bcd_fadd` does internally, and it has to happen per digit.

- **Counting the loop in bits makes the index arithmetic easy to get wrong.** Every connection has to convert between bit offset and digit number: `i +: 4` for the data and `i/4`, `i/4 - 1` for the carries. Writing `carry[i - 1]` instead of `carry[i/4 - 1]` still compiles. At `i = 4` it reads `carry[3]` instead of `carry[0]`, so digit 1's carry-in comes from digit 3's carry-out. From `i = 104` on, the index is past 99, so most digits read a carry that doesn't exist (`x` in simulation). Looping over digits removes the conversion:

  ```verilog
  for (d = 0; d < 100; d = d + 1) begin : bcd_loop
      bcd_fadd inst (.a(a[4*d +: 4]), .b(b[4*d +: 4]),
                     .cin(d == 0 ? cin : carry[d-1]),
                     .cout(carry[d]), .sum(sum[4*d +: 4]));
  end
  ```

  This also puts all 100 instances in one array (`bcd_loop[0].inst` … `bcd_loop[99].inst`). In this solution digit 0 is `inst1` and the rest are `bcd_loop[4].inst` through `bcd_loop[396].inst`, named after bit offsets rather than digit numbers. That's harder to find in a waveform viewer or netlist.

- **`i += 4` in a generate loop is SystemVerilog.** HDLBits accepts it, but a strict Verilog-2001/2005 tool doesn't: Icarus Verilog in Verilog-2005 mode reports `Compressed assignment operator requires SystemVerilog.` The portable form is `i = i + 4`. Same category as `i++` and `int` in [Vector100r](../40.%20Vector100r/README.md).

- **`bcd_fadd` isn't in the solution file.** HDLBits provides it, so following the repo's black-box convention only its declaration is quoted in a comment. Pasting your own copy into the submission can clash with the provided one, since module names are a single global namespace (see Module_fadd).

## Solution

See `bcdadd100.v`
