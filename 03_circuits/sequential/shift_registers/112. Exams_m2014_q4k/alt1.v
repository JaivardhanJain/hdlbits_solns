// Behavioural alternative: the same four-stage shift register written as
// one clocked always block instead of four instantiated flip-flops.
module top_module(
	input clk,
	input resetn,
	input in,
	output out);

	reg [3:0] sr;

	// Create a shift register named sr. It shifts in "in".
	always @(posedge clk) begin
		if (~resetn)					// Synchronous active-low reset
			sr <= 0;
		else
			sr <= {sr[2:0], in};		// shift up; "in" enters at the LSB
	end

	assign out = sr[3];					// Output the final bit (sr[3])

endmodule
