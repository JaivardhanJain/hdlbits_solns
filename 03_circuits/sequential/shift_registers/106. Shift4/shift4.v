module top_module(
	input clk,
	input areset,
	input load,
	input ena,
	input [3:0] data,
	output reg [3:0] q);

	// Asynchronous reset: notice the sensitivity list.
	// The shift register has four modes, in priority order:
	//   reset  -- asynchronous, clears q to 0
	//   load   -- q <= data (beats ena)
	//   ena    -- shift right by one, zero shifted in at q[3]
	//   idle   -- no assignment, so q holds (i.e. plain DFFs)
	always @(posedge clk, posedge areset) begin
		if (areset)			// reset
			q <= 0;
		else if (load)		// load
			q <= data;
		else if (ena)		// shift is enabled
			q <= q[3:1];	// use a vector part select to express a shift
	end

endmodule
