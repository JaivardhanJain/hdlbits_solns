# Fsm3onehot

**HDLBits link:** https://hdlbits.01xz.net/wiki/Fsm3onehot
**Category:** Circuits: Sequential (Finite State Machines)
**Difficulty:** ⭐⭐⭐

## Problem summary

The same four-state machine as [[Fsm3comb]], with the same transition table and the same output (1 only in `D`). This time the state is **one-hot encoded**: `A = 0001`, `B = 0010`, `C = 0100`, `D = 1000`. As before, the module is purely combinational. It takes `state` and `in` and produces `next_state` and `out`. The catch is that it must be written as one logic equation per state bit, derived by inspection. A `case` on the whole state vector doesn't count, and HDLBits deliberately tests with inputs that aren't one-hot to catch it.

## What one-hot encoding is

A state encoding is the mapping from state names to bit patterns stored in the state register. In [[Fsm3comb]] the four states were packed into two bits in **binary**: `00, 01, 10, 11`. **One-hot** uses one flip-flop per state instead. In a legal state, exactly one bit is 1 (it's "hot"), and that bit's position *is* the state. Four states need four flops, and the register only ever holds `0001`, `0010`, `0100` or `1000`.

The payoff shows up in the logic, not the register:

- **Recognizing a state costs nothing.** "Am I in `D`?" is `state[D]`, a single wire. With binary encoding it's a 2-input AND (`state == 2'b11`), and with more states it's a comparator on every bit. That's why the output here is just `assign out = state[D];`.
- **Next-state logic splits into small, independent equations.** Each flop only needs to answer "should *I* be hot next cycle?" That's true exactly when some state with an arrow into this one is hot *and* that arrow's condition holds. So each equation is an OR over the state's in-edges, with each term a single state bit ANDed with an input condition. Nothing has to decode the whole state vector, so the logic stays shallow however many states there are.
- **Changes stay local.** Adding a state, or an arrow, touches the equations of the states it connects and nothing else. With binary encoding, re-numbering states can perturb every next-state bit.

What it costs:

- **More flip-flops:** N flops for N states, against ⌈log₂ N⌉ for binary. For 4 states that's 4 against 2. For 32 states it's 32 against 5.
- **Lots of illegal states:** 4 flops have 16 patterns, and only 4 of them are legal (more on this in the gotchas).

## When it's useful

- **FPGAs, almost by default.** An FPGA has a flip-flop next to every LUT, so extra flops are nearly free, while logic depth is what limits clock speed. One-hot trades the cheap resource (flops) for the scarce one (wide decoding logic), so each next-state bit usually fits in one LUT level. FPGA synthesis tools such as Vivado and Quartus usually *re-encode* an FSM they recognize to one-hot automatically, unless you tell them not to.
- **Medium-sized, speed-critical FSMs:** controllers with a dozen or a few dozen states, many outputs that are "true in these states", and tight timing. Output and next-state logic stay one or two levels deep.
- **Not so much for:** ASICs where area and leakage per flop matter and the FSM is large (binary or Gray is denser), FSMs with hundreds of states (hundreds of flops), or designs where the state is stored or sent somewhere, where the extra bits cost bandwidth.

In practice you usually write the FSM with symbolic states (`localparam` or a SystemVerilog `enum`) and a `case`, as in [[Fsm1]], and let synthesis pick the encoding. Writing one-hot by hand, as in this problem, is worth knowing for two reasons. First, it's what the tool generates, so it's what you'll be reading in netlists and timing reports. Second, the derive-from-in-edges method is how you reason about the next-state logic when you're debugging it.

## Approach

Read the table *backwards*. Instead of "from `A`, where do I go?", ask "which arrows land on `A`?":

| Next state | In-edges (from state, on `in`) | Equation |
|:----------:|:-------------------------------|:---------|
| A | A on 0, C on 0 | `(A \| C) & ~in` |
| B | A on 1, B on 1, D on 1 | `(A \| B \| D) & in` |
| C | B on 0, D on 0 | `(B \| D) & ~in` |
| D | C on 1 | `C & in` |

Every arrow in the table appears in exactly one row here. That's the sanity check: 4 states × 2 input values = 8 arrows, and the right-hand column has 2 + 3 + 2 + 1 = 8 terms. The output is `D` alone.

Checking the legal one-hot inputs (for comparison with Fsm3comb's binary table):

| `state` | `in` | `next_state` | `out` |
|:-------:|:----:|:------------:|:-----:|
| A (0001) | 0 | A (0001) | 0 |
| A (0001) | 1 | B (0010) | 0 |
| B (0010) | 0 | C (0100) | 0 |
| B (0010) | 1 | B (0010) | 0 |
| C (0100) | 0 | A (0001) | 0 |
| C (0100) | 1 | D (1000) | 0 |
| D (1000) | 0 | C (0100) | 1 |
| D (1000) | 1 | B (0010) | 1 |

## Gotchas / things to watch for

- **`A`, `B`, `C`, `D` are bit *indices* here, not state *values*.** `parameter A=0, ... D=3` looks identical to [[Fsm3comb]]'s, but there `A = 0` meant "state `A` is the pattern `00`". Here it means "state `A` lives in bit 0, and its pattern is `0001`". `state == A` therefore compiles fine and is wrong: it's true only for `0000`, which isn't a legal state at all, and `state == D` would test for `0011`. Use `state[A]`. If the parameters had kept their Fsm3comb meaning, every comparison would be silently wrong. In real code, name them to say what they are, e.g. `localparam A_BIT = 0`, or define the patterns separately (`localparam [3:0] S_A = 4'b0001`).
- **Derive from in-edges, not out-edges.** The table is written per *source* state ("from `A` on 1, go to `B`"), and the instinct is to write one equation per row. That describes where each state *goes*. One-hot needs, for each flop, the conditions under which it *becomes* hot. The 8-arrow count above catches both a missing term and a duplicate.
- **Don't write a `case` on the full `state` vector.** `case (state) 4'b0001: next_state = in ? 4'b0010 : 4'b0001; ...` gives the right answer for the four legal patterns, so it *looks* equivalent. But it decodes all four bits, which throws away the whole point of one-hot. It also has no well-defined answer for the other 12 patterns. HDLBits checks exactly this by feeding non-one-hot `state` values and comparing against the per-bit equations. The equations are the specification of the circuit; the table only describes its legal subset.
- **12 of the 16 patterns are illegal, and all-zeros is a lock-up state.** Feed in `0000` and every equation needs some bit to be hot, so `next_state = 0000` forever. The machine is dead, with no error and no `x`. That's the same failure mode as the all-zeros state in [[Lfsr5]]. Two-hot states misbehave too, and they don't necessarily fix themselves straight away. `A|C = 0101` with `in = 0` collapses to `A`, but with `in = 1` it becomes `B|D = 1010`, still two-hot. `A|D = 1001` with `in = 0` becomes `A|C`. The equations carry *every* hot bit forward in parallel, so a corrupted state can wander for several cycles before it happens to merge back into one. In production you'd either guarantee the state stays legal (a solid reset, and the FSM's own register), or add recovery logic that detects "not exactly one bit set" and forces a known state. Synthesis tools can add this for you ("safe" FSM encoding). This problem deliberately leaves it out.
- **`&`/`|` and `&&`/`||` are mixed in one expression.** `state[A] & ~in || state[C] & ~in` is correct, because `&` binds tighter than `||` and every operand is 1 bit, so bitwise and logical give the same result. But it reads like two different intents, which is the [[Norgate]] distinction again. On 1-bit operands they agree. On a vector, `||` reduces to a single "is anything non-zero" bit, while `|` works bit by bit. Pick bitwise (`&`, `|`, `~`) for logic equations and use it throughout: `(state[A] | state[C]) & ~in`. Mixing them also makes it easy to reach for `!` where `~` was meant.
- **`out = state[D]` is the honest version of a trick [[Fsm1]] warned against.** There, `assign out = state;` was fragile because it relied on the binary *encoding*. Here, reading one bit directly *is* the encoding's whole purpose: one-hot guarantees `state[D]` means "in `D`". It's the same syntax with the opposite verdict, because the justification changed.
- **`next_state` is assigned bit by bit, with a continuous `assign` per bit, so the plain `output` is correct this time.** In [[Fsm3comb]] the same port, driven by an `always_comb`, needed `reg`/`logic`. Here, `assign` to slices of a net is exactly right. That's the reg-vs-net rule again, decided by how the signal is driven. It also inherits the per-bit-assignment risk from [[Lfsr5]]: a missing `assign` for one bit would leave it undriven (`z`), with no error.

## Solution

See `fsm3onehot.v`.
