// HDLBits: Module_pos
// https://hdlbits.01xz.net/wiki/Module_pos
//
// mod_a is provided by HDLBits, declared with anonymous ports:
//     module mod_a ( output, output, input, input, input, input );
// Since the ports have no names to connect to, positional connection is
// the only option here.

module top_module (
	input  a,
	input  b,
	input  c,
	input  d,
	output out1,
	output out2
);

	//            out1  out2   a  b  c  d
	//             |     |     |  |  |  |
	//           port0 port1  p2 p3 p4 p5
	mod_a inst1 ( out1, out2,  a, b, c, d );

endmodule
