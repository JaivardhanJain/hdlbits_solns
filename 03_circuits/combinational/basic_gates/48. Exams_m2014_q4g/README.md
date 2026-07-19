# Exams/m2014 q4g

**HDLBits link:** https://hdlbits.01xz.net/wiki/Exams/m2014_q4g
**Category:** Verilog Basics
**Difficulty:** ⭐⭐

## Problem summary

Given three inputs, build the circuit shown in the diagram.

## Approach

Define an intermediate wire as a result of the XNOR gate of in1 and in2 and XOR that wire with in3.

## Gotchas / things I got wrong initially
- Assigning to a signal inside `always @(*)` requires it to be declared `reg` (or `logic` in SystemVerilog) — `wire` can only be driven by `assign` or gate instantiation. My first attempt left `t` and `out` as wires while driving them procedurally, so it didn't compile. Same root cause as the `default_nettype`/implicit-wire lesson from Wire_decl, just the inverse direction — there, an undeclared wire silently appeared; here, an existing wire silently refuses procedural assignment.
- `~in1 ^ in2` and `in1 ~^ in2` are equivalent (unary `~` binds tighter than `^`, so it parses as `(~in1) ^ in2`, which is XNOR by De Morgan). Both are correct, but building XNOR by hand invites a precedence double-take every time you read it. Prefer the dedicated `~^`/`^~` operator, as used back in Xnorgate — it says what it means.

## Solution

See `exams_m2014_q4g.v`
