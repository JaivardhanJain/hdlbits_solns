# Bcdadd4

**HDLBits link:** https://hdlbits.01xz.net/wiki/Bcdadd4
**Category:** Circuits: Combinational (Arithmetic)
**Difficulty:** ⭐⭐⭐⭐

## Problem summary

You're given `bcd_fadd` — a one-digit BCD (binary-coded decimal) adder that takes two 4-bit BCD digits and a carry-in, and produces a BCD digit sum and a carry-out. Instantiate 4 copies to build a 4-digit BCD ripple-carry adder over two 16-bit-packed inputs.

## What BCD actually is

BCD packs decimal digits into 4-bit nibbles, one digit per nibble, instead of representing the whole number as one binary value. The hint gives the exact distinction worth sitting with: the decimal number 12345, in BCD, is `20'h12345` — five nibbles, each nibble holding one decimal digit (`0001 0010 0011 0100 0101`). That is *not* the same value as the plain binary encoding of 12345, which is `14'd12345` = `14'h3039`. The `'h12345` notation only looks like it's "just writing the number in hex" — what's actually happening is that each hex digit in that literal is standing in for one decimal digit, because hex digits 0–9 happen to look identical to decimal digits 0–9. Only 10 of each nibble's 16 possible values (`0000` through `1001`) are ever valid BCD; `1010`–`1111` don't correspond to any decimal digit.

This matters here because ordinary binary addition doesn't respect that constraint — add two BCD digits (say `9 + 5`) with a plain 4-bit binary adder and you get `1110` (14), which isn't a valid BCD digit at all. A real `bcd_fadd` has to detect that case and apply the "add 6" BCD correction internally to roll over into the next digit correctly. That correction logic is exactly what's hidden inside the provided `bcd_fadd` black box — this problem is purely about wiring four of them together, not about deriving the correction yourself.

## Approach

Structurally this is Adder3 and Bcdadd4 are the same shape: chain single-digit adders together, carry-out of one digit feeding carry-in of the next.

```
my_adder0: a[3:0],   b[3:0],   cin   -> c[0], sum[3:0]
my_adder1: a[7:4],   b[7:4],   c[0]  -> c[1], sum[7:4]
my_adder2: a[11:8],  b[11:8],  c[1]  -> c[2], sum[11:8]
my_adder3: a[15:12], b[15:12], c[2]  -> cout, sum[15:12]
```

The main solution uses **named port connections** — `.a(a[3:0])`, `.cin(cin)`, and so on — instead of positional ones. This is the fix for the exact risk Adder3 flagged: positional instantiation only connects correctly if the argument order matches the callee's declared port order exactly, with no compiler check if it doesn't. Named connections bind by port name instead, so the connection is correct regardless of what order `bcd_fadd`'s ports happen to be declared in, and it reads self-documenting at the call site — you can see `cin` is going to `cin` without cross-referencing the module declaration.

The three internal carries are declared as `wire c [2:0];` — worth pausing on, because it's easy to misread as identical to `wire [2:0] c;`. They're not the same declaration:

- `wire [2:0] c;` — the width `[2:0]` sits *before* the name, making `c` one **packed** 3-bit vector (a bus). `c` is a single object you could add, concatenate, or part-select as one 3-bit value.
- `wire c [2:0];` — the width `[2:0]` sits *after* the name, making `c` an **unpacked array** of three independent 1-bit wires: `c[0]`, `c[1]`, `c[2]`. There's no single "3-bit value" here at all — just three separate scalar nets that happen to share a name and be indexed.

`c[2:0]` here is the right call, not just a stylistic alternative, because these three carries are not a bus in any meaningful sense — there's no operation in this circuit that treats "the carry state" as one 3-bit number. Each `c[i]` is a single independent point-to-point wire: `my_adder0`'s carry-out feeding `my_adder1`'s carry-in, and so on, with no reason for `c[0]`, `c[1]`, and `c[2]` to ever be read, added, or compared together as a group. Declaring them as a packed vector would suggest a relationship between the bits that doesn't exist — an unpacked array of scalar wires matches what's actually going on: three separate copies of "one carry signal," not one three-times-wider signal.

`alt1.v` makes the same choice for `carry`, just wider (`carry [4:0]`, one element per carry position from `cin` through `cout`) — the reasoning is identical.

`alt1.v` builds the identical chain with a `generate`/`for` loop instead of four hand-written instances — worth knowing both. `genvar i;` declares a variable that only exists at elaboration time (compile time), not as real hardware or a simulation-time loop counter — it controls how many instances get generated, not any runtime behaviour. Each pass through the loop instantiates one `bcd_fadd`, wired to `carry[i]` and `carry[i+1]`, and slices out digit `i` with the indexed part-select `a[i*4 +:4]` (the same `+:` operator introduced back in Mux256to1v, here doing the same job: a fixed-width slice starting at a variable offset). The generate block is given a name (`begin : bcd_gen_loop`) — that's required, not decorative; unnamed generate blocks are illegal in the standard, since each generated instance needs a distinct hierarchical name to be addressable.

## Gotchas / things I got wrong initially

- **Trying to write my own `bcd_fadd` module.** Every other structural problem in this chapter (Adder3, Exams_m2014_q4j) required you to define the leaf module yourself alongside `top_module`. This one is the opposite: HDLBits already provides a `bcd_fadd` definition in its simulation environment for grading, so adding your own `module bcd_fadd (...)` in the same submission causes a duplicate-module compile error. The task here is purely instantiation and wiring — resist the urge to "complete the picture" by writing the adder you're not being asked to write.
- **Reading `20'h12345` as "the number 12345 in binary" and expecting it to equal `14'd12345`.** They're deliberately different values with the same digit string — the whole point of the hint is to stop that conflation before it causes confusion later when a testbench's BCD input doesn't match what you'd expect from converting the decimal number to plain binary in your head.
- **Miscounting the carry wires.** Four digits need exactly 3 *internal* carry wires (between digit 0→1, 1→2, 2→3) plus the external `cin` in and `cout` out — the same off-by-one risk flagged in Adder3, just easy to relitigate here because the digit count (4) and the internal-carry count (3) are one apart. In the generate version, `carry` is sized `[4:0]` (5 wires: index 0 is `cin`, indices 1–3 are internal, index 4 is the final `cout`) — get that sizing wrong and either the loop reads past the array or the final carry never reaches `cout`.
- **Assuming `wire c [2:0]` and `wire [2:0] c` are interchangeable.** They're not: `[2:0]` *before* the name declares one packed 3-bit bus; `[2:0]` *after* the name declares three separate unpacked 1-bit wires. It's tempting to treat this as a stylistic detail, but the unpacked form is the semantically correct one here — `c[0]`, `c[1]`, `c[2]` are three independent carry signals that are never used together as a combined value, so declaring them as one packed bus would misrepresent what the circuit is actually doing. The bug this causes isn't a compile error either way (both declarations let you index individual bits fine) — it shows up if you ever try to treat `c` as a single 3-bit quantity (e.g. comparing it, or part-selecting a sub-range of "the bus") when it was never a bus to begin with.
- **Assuming `i++` works in any Verilog toolchain.** The generate loop's `for (i = 0; i < 4; i++)` uses SystemVerilog's increment operator, which HDLBits's simulator accepts, but strict Verilog-2001 doesn't have `++` at all — older or stricter toolchains need `i = i + 1`. Worth knowing which language subset your actual target tool supports before assuming this syntax is portable.

## Solution

See `bcdadd4.v` for the named-instantiation form, and `alt1.v` for the generate-for-loop form.
