# Recurring gotchas

A running index of the mistakes that keep coming back across these problems.
Each entry names the concept, why it bites, and the problems where it shows up.
New problem READMEs should link back here rather than re-explaining a theme from
scratch — that's what turns a pile of solutions into a tutorial.

---

## Literals and width

**Sized vs. unsized literals.** `1` is a 32-bit signed integer; `1'b1` is one
bit. Verilog will silently resize either one to fit its context, so the wrong
literal usually doesn't error — it just quietly truncates or zero-extends.
Always size your literals.

Introduced in **Step One**. Extended in **modules_hierarchy** to port
connections, which resize just as silently when a sub-module's port width
doesn't match the net you attach.

**Self-determined width in arithmetic.** `assign {cout, sum} = a + b + cin;`
works only because the left-hand side is one bit wider than the operands — the
expression's width is determined by the *widest* operand *including* the LHS. Do
the same addition into a same-width target and the carry disappears with no
warning. See **Fadd**, **Module_fadd**.

**Zero-extension of a part select.** In **Shift4**, the zero shifted into the
top bit comes only from `q[3:1]` (3 bits) being zero-extended into a 4-bit
target. It happens to be right, but it's implicit. Write
`q <= {1'b0, q[3:1]};` so the shifted-in bit is stated, not inferred.

## Operators

**Bitwise vs. logical.** `~ & | ^` operate per bit; `! && ||` collapse their
operands to a single true/false. On 1-bit signals the two families give the same
answer, which is exactly why the habit forms — and then breaks the first time
the signal is a vector. See **Norgate**, **Andgate**, **Vectorgates**.

## Nets and declarations

**Implicit net creation.** An undeclared identifier used in a port connection or
continuous assign silently becomes a 1-bit wire. Misspell a 4-bit wire's name
and you get a 1-bit net and a truncated design, with no error. `` `default_nettype none ``
turns that silent bug into a compile error. See **Wire_decl**, **Gatesv**,
**Module_shift**.

**MSB-first declaration.** Vectors are declared `[N-1:0]`; part selects must run
in the same direction as the declaration. This is what makes "right shift" mean
"toward index 0". See **Vector0**, **Vector1**, **Shift4**.

**`output reg` only when procedurally assigned.** A signal assigned inside an
`always` block must be `reg`; one driven by a continuous assign or by a
sub-module's output port must *not* be. HDLBits compiles as SystemVerilog, so a
bare `output [N:0] q` assigned in an `always` block passes there while being
illegal Verilog-2001 — don't let the grader's leniency set your habits. See
**Dff**, and the reverse case in the structural adders.

## Procedural blocks

**Non-blocking `<=` for clocked logic, blocking `=` for combinational.** Mixing
them is the classic source of simulation/synthesis mismatch. Introduced at
**Dff**; **Module_shift8** is the reminder in the other direction.

**Multiple non-blocking assignments to the same reg resolve last-executed-wins.**
Not "in parallel" — the last one to execute in the block wins. In **Shift4**,
this is why writing `load` and `ena` as two separate `if` statements silently
inverts the intended priority, while an `else if` chain encodes it correctly.
First seen in **Edgecapture**.

**A missing `else` in a *clocked* block is a hold, not a latch.** Latch inference
is a rule about *combinational* always blocks. In a clocked block, no assignment
simply means the register keeps its value — that's a clock enable, and usually
what you wanted. The real mistake is adding `else q <= 0;` out of reflex and
destroying the hold behaviour. See **Shift4**.

**Procedural `for` vs. `generate`-`for`.** A procedural loop describes repeated
*behaviour* inside one block; a generate loop replicates *hardware* — separate
instances, separately named. They look alike and are not interchangeable. See
**Vectorr**, **Module_fadd**.

## Reset

**Registers power up as `x`.** Reset isn't hygiene, it's a functional
requirement: without it, `x` propagates through the design and simulation shows
nothing useful. See **Exams_m2014_q4d**, **Count15**, **Module_shift**.

**Async reset template.** `always @(posedge clk or posedge areset)` works *only*
for reset-like signals — there is no such trick for an async `load`, and trying
to add one produces a block that doesn't describe any real flip-flop. Introduced
at **Dff8ar**, extended at **Shift4**. In production, async reset is asserted
asynchronously and de-asserted synchronously through a two-flop reset
synchronizer, because recovery and removal timing are real constraints.

## Hierarchy and instantiation

**Named vs. positional port connection.** Named connection (`.a(x)`) turns a
wrong port *name* into a compile error instead of a silent miswire. It does
**not** catch omitted ports, wrong widths, or wrong directions — so it's a
guardrail, not a guarantee. See **Module** (20), **Module_pos**, **Module_name**.

**Unused ports.** An unused *input* may be tied to a constant: `.cin(1'b0)` is
fine. An unused *output* must be left empty: `.cout()`. Writing `.cout(1'b0)` is
illegal — a constant is not a net and cannot be driven. The two cases look
symmetric and aren't. Seen (wrongly) in **Module_add** and **Module_fadd**.

**Module names are a flat global namespace.** No packages, no scoping — two
modules named `mux2` anywhere in the compile unit collide. This is why
production codebases prefix module names by block (`fetch_mux2`). See
**Module_fadd**.

## Scaling

**Ripple-carry doesn't scale.** Each stage waits on the previous stage's carry,
so delay grows linearly with width. Fine for the 3-bit exercise, wrong for a
32-bit datapath — which is what motivates the carry-select structure. See
**Adder3**, **Module_cseladd**.

**Vector solutions scale for free; gate-level ones don't.** **Gatesv** at 4 bits
and **Gatesv100** at 100 bits are the same code. The bit-by-bit version would
have been 100 lines. Similarly, **Mux256to1** is one variable bit-select, not a
256-entry case statement.

**Variable-bound part selects are illegal.** `in[sel*4+3 : sel*4]` doesn't
compile — part-select bounds must be constant. The fixes are per-bit
concatenation or the indexed part select `in[sel*4 +: 4]`. See **Mux256to1v**.
