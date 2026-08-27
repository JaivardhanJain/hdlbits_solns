// HDLBits: Module_shift
// https://hdlbits.01xz.net/wiki/Module_shift
//
// my_dff is provided by HDLBits:
//     module my_dff ( input clk, input d, output q );

module top_module (
	input  clk,
	input  d,
	output q
);

	// Internal nets carrying the output of each stage to the next stage's
	// input. Only the two *internal* links need declaring — d and q are
	// already ports.
	wire a, b;

	// Ports connected by position: ( clk, d, q )
	//
	//   d --> [d1] --a--> [d2] --b--> [d3] --> q
	//
	my_dff d1 ( clk, d, a );
	my_dff d2 ( clk, a, b );
	my_dff d3 ( clk, b, q );

endmodule


// Alternative: same chain, ports connected by name. Preferred style once a
// sub-module has named ports (see Module_name), and it makes the "clk goes
// to every stage, data is what threads through" split explicit.
module alt1 (
	input  clk,
	input  d,
	output q
);

	wire a, b;

	my_dff d1 ( .clk(clk), .d(d), .q(a) );
	my_dff d2 ( .clk(clk), .d(a), .q(b) );
	my_dff d3 ( .clk(clk), .d(b), .q(q) );

endmodule
