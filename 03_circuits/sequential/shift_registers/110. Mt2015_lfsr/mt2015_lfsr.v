module top_module(
	input [2:0] SW,			// R
	input [1:0] KEY,		// KEY[1] = L (load), KEY[0] = clk
	output [2:0] LEDR);		// Q

	// 3-bit maximal-length Galois LFSR built from three MUXDFF cells.
	// Each cell is: D = L ? R[i] : <feedback>, clocked by KEY[0].
	//   L asserted  -> parallel load of SW into Q
	//   L deasserted -> shift toward the MSB, with Q[2] fed back
	//                   into Q[0] and XORed into Q[2].
	// Sequence (from 001): 001 -> 010 -> 100 -> 101 -> 111 -> 011 -> 110 -> 001
	// i.e. all 2^3-1 = 7 non-zero states. There is no reset; L is the
	// only way to initialize, and loading 000 locks the LFSR up.
	always @(posedge KEY[0]) begin
		if (KEY[1]) LEDR <= SW;
		else begin
			LEDR[0] <= LEDR[2];
			LEDR[1] <= LEDR[0];
			LEDR[2] <= LEDR[1] ^ LEDR[2];
		end
	end

endmodule
