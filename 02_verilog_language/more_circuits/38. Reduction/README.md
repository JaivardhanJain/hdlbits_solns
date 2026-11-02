# Reduction

**HDLBits link:** https://hdlbits.01xz.net/wiki/Reduction
**Category:** Verilog Language: More Verilog Features
**Difficulty:** ⭐⭐

## Problem summary

Compute the even parity bit for an 8-bit input `in`. The parity bit is the XOR of all 8 data bits.

## Approach

### What parity is

A parity bit is one extra bit sent along with the data so the receiver can check whether anything got flipped on the way. With **even parity**, the sender chooses the parity bit so the total number of 1s across all 9 bits (8 data + 1 parity) is even:

- data has an even number of 1s → parity bit = 0 (total stays even)
- data has an odd number of 1s → parity bit = 1 (makes the total even)

The receiver counts the 1s in all 9 bits. If the count is odd, at least one bit was corrupted.

### Why XOR computes it

XOR of two bits is 1 when exactly one of them is 1. Chain it across many bits and the result is 1 when the number of 1s is **odd**, 0 when it's even. That's exactly the even parity bit.

One way to see it: XOR is addition that throws away the carry (addition mod 2). Start at 0, and each bit either leaves the running result alone (a 0) or flips it (a 1). Two 1s flip it twice and cancel out, so only an odd number of 1s leaves it at 1.

Trace `in = 8'b10110010` (four 1s), XORing from bit 0 up:

| bit | `in[i]` | running XOR |
|---|---|---|
| 0 | 0 | 0 |
| 1 | 1 | 1 |
| 2 | 0 | 1 |
| 3 | 0 | 1 |
| 4 | 1 | 0 |
| 5 | 1 | 1 |
| 6 | 0 | 1 |
| 7 | 1 | **0** |

Four 1s, parity = 0, total stays at four. Change one bit to get `8'b10110011` (five 1s) and the result becomes 1, bringing the total to six. Both totals are even, as required.

### The reduction operator

Writing `in[7] ^ in[6] ^ ... ^ in[0]` works, but Verilog has a shorthand. A **reduction operator** is the unary form of a bitwise operator: put it in front of a single vector and it combines all of that vector's bits into one bit.

```verilog
assign parity = ^in;
```

The same works for the others:

| expression | meaning | equivalent to |
|---|---|---|
| `&in` | all bits are 1 | `in == 8'hff` |
| `\|in` | any bit is 1 | `in != 8'h00` |
| `^in` | odd number of 1s | XOR chain |
| `~&in`, `~\|in`, `~^in` | NAND, NOR, XNOR of all bits | inverted versions |

It also scales with no extra typing: `^in` is the same one line for 8 bits or 100. That's the next problem, [Gates100](https://hdlbits.01xz.net/wiki/Gates100).

## Gotchas / things I got wrong initially

- **`^in` is the even parity bit. Odd parity is `~^in`.** The names describe the *total* count of 1s you're aiming for, not the value of the bit. Even parity uses XOR; odd parity (total count odd) is the inverse, XNOR. It's easy to read "even parity" as "the parity bit is 1 when the data is even", which is the opposite. Check with the trace: four 1s in the data gives an even parity bit of 0.

- **Unary `^in` and binary `a ^ b` are the same symbol doing different jobs.** `a ^ b` XORs two vectors bit by bit and gives a vector as wide as the operands. `^in` XORs all bits of one vector together and gives 1 bit. Writing `^in` where you meant `a ^ b` (or the reverse) usually still compiles, but the width is wrong. Same idea as the bitwise vs. logical distinction from Norgate/Andgate: the same symbol can give a vector or a single bit depending on how it's used.

- **Parity only catches an odd number of flipped bits.** Each flipped bit toggles the total count of 1s, so one flip makes the count odd and gets caught. Two flips toggle it twice and the count is even again. Send `8'b10110010` with parity 0, flip bits 0 and 1 to receive `8'b10110001`. That's still four 1s, so it passes the check even though two bits are wrong. That's why links that need stronger protection use ECC or CRC, which are built out of XOR trees like this one.

## Solution

See `reduction.v`
