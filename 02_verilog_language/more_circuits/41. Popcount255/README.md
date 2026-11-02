# Popcount255

**HDLBits link:** https://hdlbits.01xz.net/wiki/Popcount255
**Category:** Verilog Language: More Verilog Features
**Difficulty:** ⭐⭐⭐

## Problem summary

Build a population count circuit: `out` is the number of bits in the 255-bit input `in` that are 1.

## Approach

Loop over every bit and add 1 to a running total for each bit that's set:

```verilog
always @(*) begin
    out = 0;
    for (int i = 0; i < 255; i++) begin
        if (in[i] == 1) out += 1;
    end
end
```

The loop syntax is the same as [Vector100r](../40.%20Vector100r/README.md). `out += 1` is SystemVerilog shorthand for `out = out + 1`.

The difference from Vector100r is that each iteration *reads* `out` as well as writing it. That works because these are blocking (`=`) assignments: each one updates `out` immediately, so the next iteration sees the new total. Scaled down to 4 bits, `in = 4'b1011`:

| `i` | `in[i]` | `out` after |
|---|---|---|
| — | — | 0 (reset) |
| 0 | 1 | 1 |
| 1 | 1 | 2 |
| 2 | 0 | 2 |
| 3 | 1 | **3** |

As always, the loop isn't hardware. Synthesis unrolls it into 255 conditional adds, each feeding the next, and the final value of `out` is what drives the port.

## Gotchas / things I got wrong initially

- **`out = 0` at the top is what keeps this combinational.** Without it, the first `out += 1` reads whatever `out` held before, so the block computes "old value + count". In hardware that's `out` feeding back into its own adder, a combinational loop rather than a counter. It's the same default-assignment idiom as [Always_nolatches](../../procedures/36.%20Always_nolatches/README.md), but here the default is also the starting value of the sum.

- **The counter has to be wide enough for the maximum count.** 255 inputs can have at most 255 ones, which is `8'hff`, so 8 bits fits exactly. That's why the problem uses 255 bits and not 256: at 256 inputs the maximum count is 256, which needs 9 bits. With an 8-bit `out`, all ones would wrap around to 0 with no error. In general a popcount of N bits needs ⌈log₂(N+1)⌉ output bits.

- **The bare `output [7:0] out` only works because HDLBits is lenient.** `out` is assigned inside an `always` block, so it needs to be a variable: `output reg [7:0] out` in Verilog, or `output logic [7:0] out` in SystemVerilog. A standard simulator rejects the HDLBits header as given. Icarus Verilog 12 reports `out is not a valid l-value ... out is declared here as wire`. With `output logic`, the same code simulates correctly. Same issue as Lfsr5 and Vector100r.

- **Written as a loop, it describes a 255-stage chain.** Each add waits for the one before it. Synthesis tools usually restructure this into something shallower, but how well they do it varies. Production popcount logic is often written as an explicit tree (add bits in pairs, then the 2-bit sums in pairs, and so on), the same chain-vs-tree point as [Conditional](../37.%20Conditional/README.md) and [Gates100](../39.%20Gates100/README.md).

## Solution

See `popcount255.v`
