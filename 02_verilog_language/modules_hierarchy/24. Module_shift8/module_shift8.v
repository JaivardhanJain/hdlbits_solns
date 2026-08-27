// HDLBits: Module_shift8
// https://hdlbits.01xz.net/wiki/Module_shift8
//
// my_dff8 is provided by HDLBits:
//     module my_dff8 ( input clk, input [7:0] d, output [7:0] q );
// The 4-to-1 mux is not provided and must be built.

module top_module (
	input        clk,
	input  [7:0] d,
	input  [1:0] sel,
	output reg [7:0] q
);

	wire [7:0] o1, o2, o3;   // output of each my_dff8 stage

	// 8-bit wide shift register, three stages deep.
	//
	//   d --> [d1] --o1--> [d2] --o2--> [d3] --o3
	//
	my_dff8 d1 ( clk, d,  o1 );
	my_dff8 d2 ( clk, o1, o2 );
	my_dff8 d3 ( clk, o2, o3 );

	// 4-to-1 mux: sel picks how many cycles of delay to take, 0 through 3.
	always @(*)
		case (sel)
			2'h0: q = d;
			2'h1: q = o1;
			2'h2: q = o2;
			2'h3: q = o3;
		endcase

endmodule


// Alternative: named port connections, and the mux written as a tap array
// indexed by sel. Scales to a deeper register without adding case arms.
module alt1 (
	input        clk,
	input  [7:0] d,
	input  [1:0] sel,
	output [7:0] q
);

	wire [7:0] tap [0:3];    // tap[0] = undelayed, tap[n] = n cycles delayed

	assign tap[0] = d;

	my_dff8 d1 ( .clk(clk), .d(tap[0]), .q(tap[1]) );
	my_dff8 d2 ( .clk(clk), .d(tap[1]), .q(tap[2]) );
	my_dff8 d3 ( .clk(clk), .d(tap[2]), .q(tap[3]) );

	assign q = tap[sel];

endmodule
