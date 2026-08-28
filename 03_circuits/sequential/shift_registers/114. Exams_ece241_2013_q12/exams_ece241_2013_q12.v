// 8x1 memory written serially and read random-access -- i.e. a 3-input LUT.
// An 8-bit shift register holds the contents; a 8-to-1 mux selects one bit.
module top_module(
	input clk,
	input enable,
	input S,

	input A, B, C,
	output reg Z);

	reg [7:0] q;

	// The final circuit is a shift register attached to an 8-to-1 mux.

	// 8-to-1 mux: use {A,B,C} as a 3-bit number and index the vector with it.
	// There are many other ways to write an 8-to-1 mux (e.g. a combinational
	// always block with an 8-way case statement).
	assign Z = q[{A, B, C}];

	// Edge-triggered always block: a standard shift register (named q) with
	// an enable. When enabled, shift toward the MSB (discarding q[7] and
	// shifting S into q[0]).
	always @(posedge clk) begin
		if (enable)
			q <= {q[6:0], S};
	end

endmodule
