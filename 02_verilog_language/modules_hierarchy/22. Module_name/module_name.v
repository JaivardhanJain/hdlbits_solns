// HDLBits: Module_name
// https://hdlbits.01xz.net/wiki/Module_name
//
// mod_a is provided by HDLBits:
//     module mod_a ( output out1, output out2,
//                    input in1, input in2, input in3, input in4 );
//
// Note the connections below are written inputs-first while mod_a declares
// its outputs first. With named connection that difference is irrelevant.

module top_module (
	input  a,
	input  b,
	input  c,
	input  d,
	output out1,
	output out2
);

	mod_a inst1 (
		.in1  (a),
		.in2  (b),
		.in3  (c),
		.in4  (d),
		.out1 (out1),
		.out2 (out2)
	);

endmodule
