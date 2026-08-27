module top_module(
	input clk,
	input load,
	input [1:0] ena,
	input [99:0] data,
	output reg [99:0] q);

	// This rotator has 4 modes:
	//   load
	//   rotate right (ena == 2'b01)
	//   rotate left  (ena == 2'b10)
	//   do nothing   (ena == 2'b00 or 2'b11)
	// Vector part-select + concatenation express the rotation.
	// Edge-sensitive always block: use non-blocking assignments.
	always @(posedge clk) begin
		if (load)					// Load
			q <= data;
		else if (ena == 2'h1)		// Rotate right
			q <= {q[0], q[99:1]};
		else if (ena == 2'h2)		// Rotate left
			q <= {q[98:0], q[99]};
	end

endmodule
