// 4-bit shift register with enable and parallel load, built from four
// copies of the MUXDFF cell from Exams_2014_q4a.
//
// DE2 board mapping (from the problem):
//   SW[3:0] -> R (parallel load data)   KEY[0] -> clk
//   KEY[1]  -> E (shift enable)         KEY[2] -> L (load)
//   KEY[3]  -> w (serial input)         LEDR[3:0] -> Q
//
// Data flows from bit 3 down to bit 0: the external serial input enters
// dff3, and each lower stage takes the stage above it.
module top_module(
	input [3:0] SW,
	input [3:0] KEY,
	output [3:0] LEDR);

	MUXDFF dff3 (.clk(KEY[0]), .E(KEY[1]), .L(KEY[2]), .w(KEY[3]),   .R(SW[3]), .Q(LEDR[3]));
	MUXDFF dff2 (.clk(KEY[0]), .E(KEY[1]), .L(KEY[2]), .w(LEDR[3]),  .R(SW[2]), .Q(LEDR[2]));
	MUXDFF dff1 (.clk(KEY[0]), .E(KEY[1]), .L(KEY[2]), .w(LEDR[2]),  .R(SW[1]), .Q(LEDR[1]));
	MUXDFF dff0 (.clk(KEY[0]), .E(KEY[1]), .L(KEY[2]), .w(LEDR[1]),  .R(SW[0]), .Q(LEDR[0]));

endmodule


// One stage: two muxes feeding a D flip-flop.
//   L asserted        -> load R
//   L low, E asserted -> take w (shift)
//   both low          -> hold Q
// Same cell as Exams_2014_q4a, here written with continuous assignments
// instead of an always @(*) block.
module MUXDFF(
	input clk,
	input E,
	input L,
	input w,
	input R,
	output reg Q);

	wire D, t;

	assign t = E ? w : Q;		// enable mux: shift in w, or hold Q
	assign D = L ? R : t;		// load mux: L overrides E

	always @(posedge clk) begin
		Q <= D;
	end

endmodule
