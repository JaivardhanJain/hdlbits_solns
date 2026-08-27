// Structural solution: four instances of a single-bit D flip-flop with
// an active-low synchronous reset, chained input to output.
// `in` reaches `out` four clock cycles later.
module top_module(
	input clk,
	input resetn,		// synchronous, active-low
	input in,
	output out);

	// NOTE: this declares an *unpacked array* of three 1-bit nets, not a
	// 3-bit vector (that would be `wire [2:0] t;`). It works here because
	// every use is a single-element index, but see the README gotchas.
	wire t[2:0];

	my_dff dff0 (.clk(clk), .reset(resetn), .d(in),   .q(t[0]));
	my_dff dff1 (.clk(clk), .reset(resetn), .d(t[0]), .q(t[1]));
	my_dff dff2 (.clk(clk), .reset(resetn), .d(t[1]), .q(t[2]));
	my_dff dff3 (.clk(clk), .reset(resetn), .d(t[2]), .q(out));

endmodule


// One stage of the chain. Note that `reset` carries an active-LOW signal
// despite its name -- see the README gotchas.
module my_dff(
	input clk,
	input reset,
	input d,
	output reg q);

	always @(posedge clk) begin
		if (~reset) q <= 0;
		else        q <= d;
	end

endmodule
