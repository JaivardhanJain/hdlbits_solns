# CLAUDE.md — working notes for this repo

Context for any Claude session (or human contributor) working in `hdlbits_solns`.
This file is the portable source of truth: it is committed to git, so it travels
between machines. Anything durable learned about how this repo works belongs
here, not in a session's memory.

## What this repo is

A public tutorial repo of [HDLBits](https://hdlbits.01xz.net/wiki/Main_Page)
Verilog solutions. The goal is **teaching industry best practice and calling out
easy-to-make mistakes**, not just posting code that passes the grader. Every
problem gets a README explaining the approach and the gotchas; the `.v` file
alone is not the deliverable.

## Repo layout

```
01_getting_started/
02_verilog_language/
    basics/  vectors/  modules_hierarchy/  procedures/  more_circuits/
03_circuits/
    combinational/
        basic_gates/  multiplexers/  arithmetic_circuits/  karnaugh_maps/
    sequential/
        latches_and_flipflops/  counters/  shift_registers/  finite_state_machines/
04_verification_testbenches/
```

Each problem lives in its own numbered subfolder, e.g.
`02_verilog_language/vectors/18. Vector4/`, containing a `README.md` and the
solution `.v` file.

**Folder names are not guessable from the HDLBits category label.** Note
`arithmetic_circuits` (not `arithmetic`) and `modules_hierarchy` (not
`modules`). Before creating a problem folder, list the parent category
directory and reuse the exact existing name — a near-miss duplicate splits one
category across two folders.

## Conventions

**Solution filenames** are named after the problem: `xnor_gate.v`, `vector4.v`,
`gates4.v`. Not a uniform `solution.v`. (The template README still says
`solution.v` — the per-problem name wins.)

**Folder numbering tracks HDLBits's own problem order.** A skipped problem
leaves a numeric gap; numbers are never shifted down to close one. Before adding
a problem, check the HDLBits sidebar ordering and confirm the previous folder's
number is right.

**Multiple valid approaches stay in the repo.** When a problem admits several
reasonable implementations (gate primitives vs. continuous assign vs.
intermediate wires), keep them all as separate named modules — `top_module`,
`alt1`, `alt2` — rather than keeping one and describing the others in prose.
Depending on the problem they may live in one file or in a sibling file
(e.g. Count_clock ships `count_clock.v` plus `alt1.v`).

**Black-box modules.** HDLBits-provided sub-modules whose bodies you do not
write (`add16`, the given DFFs, etc.) are **not** included in the solution file
— only their declaration is quoted in a comment. Helper sub-modules you wrote
yourself (Adder3's `fa`, Countbcd's `bcdcounter`, Module_fadd's `add1`) **are**
included.

**READMEs follow** `01_getting_started/_TEMPLATE_README.md`: Problem summary /
Approach / Gotchas / Solution. Descriptions are in your own words — never
copy-pasted wiki text.

**The top-level module must be named exactly `top_module`.** This has been a
real bug in this repo more than once.

## Adding a problem — checklist

1. Confirm the correct category folder name (reuse, don't invent).
2. Create the numbered folder, matching HDLBits's ordering, leaving gaps intact.
3. Write the `.v` file, named after the problem.
4. Write `README.md` from the template.
5. Insert a row in the main `README.md` table.
6. Update the "gaps" note in the prose below the table if the gap set changed.

## Review workflow

When reviewing a draft README or solution:

1. **Fetch the live HDLBits page** (`https://hdlbits.01xz.net/wiki/<ProblemName>`)
   before judging accuracy. Exact port names, widths, and spec details matter
   because solutions must actually pass the grader — never assume from the
   problem name.
2. **Read the actual `.v` file in the repo**, not just the README.
3. **Write gotchas as original prose**, and where possible connect them back to
   a concept already established in the series (see `GOTCHA_THEMES.md`). This
   makes the tutorial a coherent thread rather than isolated notes.
4. **Don't edit files until asked.** Present findings and proposed fixes first
   and wait for a go-ahead. (Once a pattern has been approved several problems
   running, a short "ok" is a sufficient green light.)

### Recurring hygiene bugs — check for these every time

- Stray content copy-pasted from the previous problem's folder (an entire README
  section once survived from a different problem).
- Module named `top_module1` / `top_module2` instead of `top_module`.
- Solution file misnamed after a different problem.
- Folder numbering drifted off HDLBits order.
- Invisible unicode characters inside code blocks.
- `.cout(1'b0)` on an unused **output** port. Illegal — a constant is not a net
  and cannot be driven by an output. The correct form is the empty connection
  `.cout()`. The mirror case `.cin(1'b0)` on an *input* is legal, which is why
  the mistake looks plausible. This has appeared twice (Module_add, Module_fadd);
  check any adder problem for it.

## Tooling

No simulator (iverilog) is available in the Claude sandbox and installing one
isn't permitted, so solutions **cannot be compile-checked** — they are reviewed
by reading. Treat any claim that code "compiles" with suspicion.

## Working from more than one machine

The repo is the only thing that syncs. Sessions and their memory are tied to a
single machine, which is why this file exists.

- Clone from GitHub to a **normal local path**, not inside a cloud-synced folder.
  Two machines syncing a live `.git` directory through OneDrive/Dropbox will
  eventually corrupt the index or produce phantom conflicts.
- `git pull` at the start of a session, `git push` at the end. Don't leave work
  uncommitted when switching machines.
- When a new convention or gotcha pattern is established, write it into this
  file or `GOTCHA_THEMES.md` and commit it, so the other machine inherits it.
