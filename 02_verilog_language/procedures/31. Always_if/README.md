# Always_if

**HDLBits link:** https://hdlbits.01xz.net/wiki/Always_if
**Category:** Verilog Language: Procedures
**Difficulty:** ⭐

## Problem summary

Build a 2-to-1 multiplexer that outputs `b` when **both** `sel_b1` and `sel_b2` are 1, and `a` otherwise. Write it twice: once with an `assign` and the conditional operator `?:`, and once with an `if`/`else` inside a combinational `always` block.

## Approach

| `sel_b1` | `sel_b2` | output |
|:-:|:-:|:-:|
| 0 | 0 | `a` |
| 0 | 1 | `a` |
| 1 | 0 | `a` |
| 1 | 1 | `b` |

It's a mux whose select line is `sel_b1 & sel_b2`. The two styles describe the same hardware, one AND gate feeding one 2-to-1 mux:

```verilog
assign out_assign = sel_b1 && sel_b2 ? b : a;

always @(*) begin
    if (sel_b1 && sel_b2) out_always = b;
    else                  out_always = a;
end
```

An `if`/`else` in a combinational block is the procedural version of `?:`. The condition drives the mux's select, the `if` branch is the "1" input, and the `else` branch is the "0" input. [Alwaysblock1](../29.%20Alwaysblock1/README.md) and [Mux2to1](../../../03_circuits/combinational/multiplexers/61.%20Mux2to1/README.md) cover the rest.

`?:` is shorter for a single 2-way choice like this one. `if`/`else` becomes the better option once the choices nest several levels deep or several outputs are assigned under the same condition. A chain of `?:` gets hard to read quickly.

## Gotchas / things I got wrong initially

- **My first draft left out the `assign` keyword.** `out_assign = sel_b1 && sel_b2 ? b : a;` on its own at module level is a syntax error. Outside a procedure, a continuous assignment has to start with `assign`. Inside an `always` block, it must *not*. The table in [Alwaysblock2](../30.%20Alwaysblock2/README.md) lists where each kind of assignment is legal.

- **Leave out the `else` and you get a latch, not a mux.** This is the main lesson of the chapter. Consider:

  ```verilog
  always @(*) begin
      if (sel_b1 && sel_b2) out_always = b;   // no else
  end
  ```

  When the condition is false, nothing assigns `out_always`, so it has to keep its previous value. A block with no clock can only do that with a **latch**:

  | Step | `sel_b1` | `sel_b2` | `a` | `b` | `out_always` |
  |:-:|:-:|:-:|:-:|:-:|:-:|
  | 1 | 1 | 1 | 0 | 1 | 1 (follows `b`) |
  | 2 | 0 | 1 | 0 | 1 | **1** (held; should be `a` = 0) |
  | 3 | 0 | 1 | 0 | 0 | **1** (still held) |

  It compiles, and synthesis only gives a warning ("inferred latch for out_always"). The circuit now has memory it shouldn't. Latches also cause timing-analysis headaches in FPGA and ASIC flows. The rule for combinational blocks: **every output is assigned on every path.** In a *clocked* block, the same missing `else` is a harmless hold ([Shift4](../../../03_circuits/sequential/shift_registers/106.%20Shift4/README.md)). Latch inference only happens in combinational blocks. [Exams_m2014_q4a](../../../03_circuits/sequential/latches_and_flipflops/86.%20Exams_m2014_q4a/README.md) is the one problem that *wants* a latch and uses this same pattern on purpose.

- **Set a default at the top of the block.** An industry habit that makes the latch impossible:

  ```verilog
  always @(*) begin
      out_always = a;                           // default
      if (sel_b1 && sel_b2) out_always = b;     // override
  end
  ```

  Because blocking `=` is last-write-wins within the block, this is the same mux. It stays latch-free no matter how many branches you add later. It's worth it in blocks with several outputs and nested conditions, where a missing `else` is easy to overlook.

- **Nested `if`s have a dangling-`else` trap.** Splitting the `&&` into two `if`s looks equivalent:

  ```verilog
  if (sel_b1)
      if (sel_b2) out_always = b;
  else            out_always = a;   // attaches to if (sel_b2), NOT if (sel_b1)
  ```

  An `else` always attaches to the *nearest* unmatched `if`, whatever the indentation says. So when `sel_b1 = 0`, no branch runs, `out_always` isn't assigned, and you get a latch again. Combine the conditions with `&&` as the solution does, or use `begin`/`end` to make the nesting explicit.

- **`&&` vs. `&`.** For 1-bit operands they give the same result, so either works here. They differ on vectors: `&&` asks "are both non-zero?" and returns 1 bit, while `&` ANDs bit by bit and returns a vector. That's the same split as `!` vs. `~` in [Norgate](../../basics/7.%20Norgate/README.md). A useful convention: `&&` in conditions (it reads as "and also"), `&` in datapath expressions.

- **`?:` has very low precedence.** `sel_b1 && sel_b2 ? b : a` parses as `(sel_b1 && sel_b2) ? b : a` because `&&` binds tighter than `?:`, so the solution is correct. The same low precedence bites in the other direction, though. For example, `x | sel ? b : a` parses as `(x | sel) ? b : a`, not `x | (sel ? b : a)`. Wrap the condition in parentheses and nobody has to remember the precedence table.

- **The two styles differ in simulation when a select is `x`.** If `sel_b1` or `sel_b2` is unknown, `if (x)` is treated as false and takes the `else` branch, so `out_always` shows a clean `a`. `?:` with an `x` condition merges both inputs bit by bit, so `out_assign` shows `x` wherever `a` and `b` differ. The hardware is identical. Only the simulator's view differs, and here the `if` version is the one hiding a problem. This is called *x-optimism*, and it's one reason some teams prefer `?:` or add assertions on select lines.

## Solution

See `always_if.v`
