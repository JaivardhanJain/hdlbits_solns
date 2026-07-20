# hdlbits_solns

Solutions to [HDLBits](https://hdlbits.01xz.net/wiki/Main_Page) (the Verilog problem set) with explanations, gotchas, and industry best practices — not just working code. Each problem has its own folder with a `README.md` (problem summary, approach, gotchas) and a `.v` solution file.

## Problems

| # | Problem | Category | Difficulty | Description |
|---|---------|----------|:----------:|--------------|
| 1 | [Step One](01_getting_started/1.%20Step%20One/README.md) | Getting Started | ⭐ | Set a constant output to 1; simplest possible module. |
| 2 | [Zero](01_getting_started/2.%20Zero/README.md) | Getting Started | ⭐ | Set a constant output to 0. |
| 3 | [Wire](02_verilog_language/basics/3.%20Wire/README.md) | Verilog Language: Basics | ⭐ | Wire an input straight through to an output. |
| 4 | [Wire4](02_verilog_language/basics/4.%20Wire4/README.md) | Verilog Language: Basics | ⭐ | Fan the same 3 inputs out to 4 outputs. |
| 5 | [NotGate](02_verilog_language/basics/5.%20NotGate/README.md) | Verilog Language: Basics | ⭐ | Invert a single input. |
| 6 | [Andgate](02_verilog_language/basics/6.%20Andgate/README.md) | Verilog Language: Basics | ⭐ | AND two inputs together. |
| 7 | [Norgate](02_verilog_language/basics/7.%20Norgate/README.md) | Verilog Language: Basics | ⭐ | NOR two inputs; first use of combined bitwise operators. |
| 8 | [Xnorgate](02_verilog_language/basics/8.%20Xnorgate/README.md) | Verilog Language: Basics | ⭐ | XNOR two inputs. |
| 9 | [Wire_decl](02_verilog_language/basics/9.%20Wire%20decl/README.md) | Verilog Language: Basics | ⭐ | Declare intermediate wires and combine gates through them. |
| 10 | [7458](02_verilog_language/basics/10.%207458/README.md) | Verilog Language: Basics | ⭐⭐ | Emulate a real 7458 quad AND-OR-invert chip using wires and assigns. |
| 11 | [Vector0](02_verilog_language/vectors/11.%20Vector0/README.md) | Verilog Language: Vectors | ⭐ | Pass a 3-bit vector through, both whole and split into individual bits. |
| 12 | [Vector1](02_verilog_language/vectors/12.%20Vector1/README.md) | Verilog Language: Vectors | ⭐ | Split a 16-bit vector into two halves with part-select. |
| 13 | [Vector2](02_verilog_language/vectors/13.%20Vector2/README.md) | Verilog Language: Vectors | ⭐ | Split a 32-bit vector into four bytes with part-select. |
| 14 | [Vectorgates](02_verilog_language/vectors/14.%20Vectorgates/README.md) | Verilog Language: Vectors | ⭐ | Apply bitwise and logical operators across a vector. |
| 15 | [Gates4](02_verilog_language/vectors/15.%20Gates4/README.md) | Verilog Language: Vectors | ⭐ | Run a 4-bit vector through multi-input gates. |
| 16 | [Vector3](02_verilog_language/vectors/16.%20Vector3/README.md) | Verilog Language: Vectors | ⭐ | Concatenate several input vectors and re-split into outputs. |
| 17 | [Vectorr](02_verilog_language/vectors/17.%20Vectorr/README.md) | Verilog Language: Vectors | ⭐ | Reverse the bit order of a vector. |
| 18 | [Vector4](02_verilog_language/vectors/18.%20Vector4/README.md) | Verilog Language: Vectors | ⭐ | Sign-extend an 8-bit vector to 32 bits. |
| 19 | [Vector5](02_verilog_language/vectors/19.%20Vector5/README.md) | Verilog Language: Vectors | ⭐⭐ | Compute all pairwise comparisons across 5 inputs into a 25-bit output. |
| 44 | [Exams_m2014_q4h](03_circuits/combinational/basic_gates/44.%20Exams_m2014_q4h/README.md) | Circuits: Combinational (Basic Gates) | ⭐ | Wire an input to an output. |
| 45 | [Exams_m2014_q4i](03_circuits/combinational/basic_gates/45.%20Exams_m2014_q4i/README.md) | Circuits: Combinational (Basic Gates) | ⭐ | Tie an output permanently low. |
| 46 | [Exams_m2014_q4e](03_circuits/combinational/basic_gates/46.%20Exams_m2014_q4e/README.md) | Circuits: Combinational (Basic Gates) | ⭐ | NOR two inputs. |
| 47 | [Exams_m2014_q4f](03_circuits/combinational/basic_gates/47.%20Exams_m2014_q4f/README.md) | Circuits: Combinational (Basic Gates) | ⭐ | Invert one input and AND it with the other. |
| 48 | [Exams_m2014_q4g](03_circuits/combinational/basic_gates/48.%20Exams_m2014_q4g/README.md) | Circuits: Combinational (Basic Gates) | ⭐⭐ | Build a 3-input circuit from a given gate diagram. |
| 49 | [Gates](03_circuits/combinational/basic_gates/49.%20Gates/README.md) | Circuits: Combinational (Basic Gates) | ⭐ | Drive 7 outputs from 2 inputs through various gates. |
| 50 | [7420](03_circuits/combinational/basic_gates/50.%207420/README.md) | Circuits: Combinational (Basic Gates) | ⭐ | Emulate a real 7420 dual 4-input NAND chip. |
| 51 | [Truthtable1](03_circuits/combinational/basic_gates/51.%20Truthtable1/README.md) | Circuits: Combinational (Basic Gates) | ⭐⭐⭐ | Synthesize a circuit directly from a given truth table. |
| 52 | [Mt2015_eq2](03_circuits/combinational/basic_gates/52.%20Mt2015_eq2/README.md) | Circuits: Combinational (Basic Gates) | ⭐⭐ | Compare two 2-bit vectors for equality. |
| 53 | [Mt2015_q4a](03_circuits/combinational/basic_gates/53.%20Mt2015_q4a/README.md) | Circuits: Combinational (Basic Gates) | ⭐ | Implement a given boolean equation directly. |
| 54 | [Mt2015_q4b](03_circuits/combinational/basic_gates/54.%20Mt2015_q4b/README.md) | Circuits: Combinational (Basic Gates) | ⭐⭐ | Match a circuit to a given simulation waveform (turns out to be XNOR). |
| 55 | [Mt2015_q4](03_circuits/combinational/basic_gates/55.%20Mt2015_q4/README.md) | Circuits: Combinational (Basic Gates) | ⭐⭐ | Instantiate q4a/q4b's modules and combine them with extra logic. |
| 56 | [Ringer](03_circuits/combinational/basic_gates/56.%20Ringer/README.md) | Circuits: Combinational (Basic Gates) | ⭐⭐ | Translate a written phone-ringer spec into declarative `assign` logic. |
| 57 | [Thermostat](03_circuits/combinational/basic_gates/57.%20Thermostat/README.md) | Circuits: Combinational (Basic Gates) | ⭐⭐ | Translate a written thermostat spec into declarative `assign` logic. |
| 58 | [Popcount3](03_circuits/combinational/basic_gates/58.%20Popcount3/README.md) | Circuits: Combinational (Basic Gates) | ⭐⭐ | Count set bits in a 3-bit vector (a full adder in disguise). |
| 59 | [Gatesv](03_circuits/combinational/basic_gates/59.%20Gatesv/README.md) | Circuits: Combinational (Basic Gates) | ⭐⭐ | Compare each bit of a 4-bit vector to its neighbour (AND/OR/XOR, with wraparound). |
| 60 | [Gatesv100](03_circuits/combinational/basic_gates/60.%20Gatesv100/README.md) | Circuits: Combinational (Basic Gates) | ⭐⭐ | Same as Gatesv, widened to 100 bits — the vector solution scales unchanged. |
| 61 | [Mux2to1](03_circuits/combinational/multiplexers/61.%20Mux2to1/README.md) | Circuits: Combinational (Multiplexers) | ⭐ | One-bit 2-to-1 multiplexer: `sel=0` picks `a`, `sel=1` picks `b`. |

Numbering follows HDLBits's own problem order, so gaps (20–43) mark chapters — Modules: Hierarchy, Procedures, More Verilog Features — not yet solved.
