// HDLBits: Module_fadd
// https://hdlbits.01xz.net/wiki/Module_fadd
//
// Three levels of hierarchy:
//     top_module  (ours)   instantiates two of...
//     add16       (given)  which internally instantiates 16 of...
//     add1        (ours)   a 1-bit full adder.
//
// add16 is provided by HDLBits and its body is not shown to us:
//     module add16 ( input [15:0] a, input [15:0] b, input cin,
//                    output [15:0] sum, output cout );

module top_module (
	input  [31:0] a,
	input  [31:0] b,
	output [31:0] sum
);

	wire c;   // carry from the low half into the high half

	add16 a1 (
		.a    (a[15:0]),
		.b    (b[15:0]),
		.cin  (1'b0),
		.sum  (sum[15:0]),
		.cout (c)
	);

	add16 a2 (
		.a    (a[31:16]),
		.b    (b[31:16]),
		.cin  (c),
		.sum  (sum[31:16]),
		.cout ()      // unused output: left empty, NOT tied to a constant
	);

endmodule


// 1-bit full adder. Nothing here instantiates it — add16 does, sixteen times,
// from inside its own body. The declaration must match what add16 expects.
module add1 (
	input  a,
	input  b,
	input  cin,
	output sum,
	output cout
);

	// The 2-bit LHS concatenation makes the addition evaluate at 2 bits,
	// so the carry lands in cout instead of being truncated away.
	assign {cout, sum} = a + b + cin;

	// Equivalent gate-level form (HDLBits's hint), same synthesised result:
	//   assign sum  = a ^ b ^ cin;
	//   assign cout = (a & b) | (a & cin) | (b & cin);

endmodule
