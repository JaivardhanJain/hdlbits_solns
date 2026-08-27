// HDLBits: Module_cseladd
// https://hdlbits.01xz.net/wiki/Module_cseladd
//
// add16 is provided by HDLBits:
//     module add16 ( input [15:0] a, input [15:0] b, input cin,
//                    output [15:0] sum, output cout );

module top_module (
	input  [31:0] a,
	input  [31:0] b,
	output [31:0] sum
);

	wire        t1;        // carry out of the low half — the mux select
	wire [15:0] t2, t3;    // speculative upper sums for cin = 0 and cin = 1
	reg  [15:0] hi;        // chosen upper half (procedurally assigned)

	// Low half. Drives sum[15:0] directly and produces the real carry.
	add16 a1 (
		.a    (a[15:0]),
		.b    (b[15:0]),
		.cin  (1'b0),
		.sum  (sum[15:0]),
		.cout (t1)
	);

	// Upper half computed twice, in parallel, without waiting for t1.
	add16 a2 (
		.a    (a[31:16]),
		.b    (b[31:16]),
		.cin  (1'b0),
		.sum  (t2),
		.cout ()          // unused output: empty, not tied to a constant
	);

	add16 a3 (
		.a    (a[31:16]),
		.b    (b[31:16]),
		.cin  (1'b1),
		.sum  (t3),
		.cout ()
	);

	// 16-bit wide 2-to-1 mux: pick the answer that matches the real carry.
	always @(*)
		case (t1)
			1'b0: hi = t2;
			1'b1: hi = t3;
		endcase

	// hi is a reg, so it reaches the output port through a continuous
	// assign. sum[15:0] is driven structurally by a1 — the two halves of
	// sum are driven by different mechanisms, which is why the mux cannot
	// write sum[31:16] directly.
	assign sum[31:16] = hi;

endmodule


// Alternative: the same mux written as a conditional continuous assignment,
// which removes the reg and the always block entirely.
module alt1 (
	input  [31:0] a,
	input  [31:0] b,
	output [31:0] sum
);

	wire        t1;
	wire [15:0] t2, t3;

	add16 a1 ( .a(a[15:0]),  .b(b[15:0]),  .cin(1'b0), .sum(sum[15:0]), .cout(t1) );
	add16 a2 ( .a(a[31:16]), .b(b[31:16]), .cin(1'b0), .sum(t2),        .cout()   );
	add16 a3 ( .a(a[31:16]), .b(b[31:16]), .cin(1'b1), .sum(t3),        .cout()   );

	assign sum[31:16] = t1 ? t3 : t2;

endmodule
