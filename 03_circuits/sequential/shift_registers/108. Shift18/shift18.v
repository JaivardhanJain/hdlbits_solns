module top_module(
	input clk,
	input load,
	input ena,
	input [1:0] amount,
	input [63:0] data,
	output reg [63:0] q);

	// 64-bit ARITHMETIC shifter with synchronous load.
	//   load          -- q <= data (ignores ena)
	//   ena, amount:
	//     2'b00       -- shift left  by 1
	//     2'b01       -- shift left  by 8
	//     2'b10       -- shift right by 1, sign-extending
	//     2'b11       -- shift right by 8, sign-extending
	//   otherwise     -- hold
	// Left shifts fill with zeros; right shifts replicate q[63].
	always @(posedge clk) begin
		if (load) q <= data;
		else begin
			if (ena) begin
				case (amount)
					2'b00: q <= {q[62:0], 1'b0};
					2'b01: q <= {q[55:0], {8{1'b0}}};
					2'b10: q <= {q[63], q[63:1]};
					2'b11: q <= {{8{q[63]}}, q[63:8]};
				endcase
			end
		end
	end

endmodule
