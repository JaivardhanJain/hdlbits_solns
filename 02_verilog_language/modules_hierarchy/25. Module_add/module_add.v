// HDLBits: Module_add
// https://hdlbits.01xz.net/wiki/Module_add
//
// add16 is provided by HDLBits:
//     module add16 ( input [15:0] a, input [15:0] b, input cin,
//                    output [15:0] sum, output cout );

module top_module (
	input  [31:0] a,
	input  [31:0] b,
	output [31:0] sum
);

	wire c;   // carry from the low half into the high half

	// Low half: no carry in, carry out feeds the upper adder.
	add16 a1 (
		.a    (a[15:0]),
		.b    (b[15:0]),
		.cin  (1'b0),
		.sum  (sum[15:0]),
		.cout (c)
	);

	// High half: takes the carry, and its own carry out is discarded.
	// An unused OUTPUT is left explicitly empty — it cannot be tied to a
	// constant, since a constant is not a net and cannot be driven.
	add16 a2 (
		.a    (a[31:16]),
		.b    (b[31:16]),
		.cin  (c),
		.sum  (sum[31:16]),
		.cout ()
	);

endmodule
