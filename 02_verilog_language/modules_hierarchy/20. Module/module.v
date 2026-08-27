// HDLBits: Module
// https://hdlbits.01xz.net/wiki/Module
//
// mod_a is provided by HDLBits as a black box. Only its port list matters:
//     module mod_a ( input in1, input in2, output out );

// Preferred style: connect by name.
module top_module (
	input  a,
	input  b,
	output out
);

	mod_a inst1 (
		.in1 (a),   // mod_a's port "in1" <- top_module's wire "a"
		.in2 (b),   // mod_a's port "in2" <- top_module's wire "b"
		.out (out)  // mod_a's port "out" -> top_module's wire "out"
		            // (mod_a's "out" and top_module's "out" are separate
		            //  signals that happen to share a name)
	);

endmodule


// Alternative: connect by position. Legal, and accepted by the grader, but
// silently breaks if mod_a's port order ever changes.
module alt1 (
	input  a,
	input  b,
	output out
);

	mod_a inst2 ( a, b, out );  // -> in1, in2, out in declaration order

endmodule
