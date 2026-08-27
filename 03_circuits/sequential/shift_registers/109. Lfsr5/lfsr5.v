module top_module(
	input clk,
	input reset,		// Active-high synchronous reset to 5'h1
	output [4:0] q);

	// 5-bit maximal-length Galois LFSR, taps at positions 5 and 3
	// (1-indexed) == q[4] and q[2] in Verilog's 0-indexed notation.
	//   - the output bit q[0] feeds back into the top bit q[4]
	//   - the tapped bit q[2] takes q[3] XOR the feedback bit
	//   - every other bit just shifts down one position
	// Reset is to 5'h1, not 0: all-zeros is a lock-up state.
	always @(posedge clk) begin
		if (reset) q <= 5'h1;
		else begin
			q[4]   <= q[0];
			q[3]   <= q[4];
			q[2]   <= q[3] ^ q[0];
			q[1:0] <= q[2:1];
		end
	end

endmodule
