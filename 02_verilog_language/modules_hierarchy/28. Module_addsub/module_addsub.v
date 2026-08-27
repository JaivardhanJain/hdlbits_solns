// HDLBits: Module_addsub
// https://hdlbits.01xz.net/wiki/Module_addsub
//
// add16 is provided by HDLBits:
//     module add16 ( input [15:0] a, input [15:0] b, input cin,
//                    output [15:0] sum, output cout );

module top_module (
	input  [31:0] a,
	input  [31:0] b,
	input         sub,
	output [31:0] sum
);

	wire c;   // carry between the two 16-bit halves

	// Conditionally invert every bit of b.
	//   sub = 0 -> {32{1'b0}} = 32'h00000000 -> b_sub = b      (add)
	//   sub = 1 -> {32{1'b1}} = 32'hFFFFFFFF -> b_sub = ~b     (subtract)
	// The replication is essential: a bare `b ^ sub` would zero-extend the
	// 1-bit sub to 32 bits and only flip bit 0.
	wire [31:0] b_sub = b ^ {32{sub}};

	// sub also feeds cin, supplying the +1 that completes ~b + 1 = -b.
	add16 my_adder0 ( .a(a[15:0]),  .b(b_sub[15:0]),  .cin(sub), .sum(sum[15:0]),  .cout(c)  );
	add16 my_adder1 ( .a(a[31:16]), .b(b_sub[31:16]), .cin(c),   .sum(sum[31:16]), .cout()   );

endmodule
