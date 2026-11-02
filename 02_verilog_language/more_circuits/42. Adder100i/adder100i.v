// HDLBits: Adder100i
// https://hdlbits.01xz.net/wiki/Adder100i
//
// 100-bit ripple-carry adder built from 100 instantiated full adders
// (generate-for). Every stage's carry-out is exposed on cout.
// See alt1.v for a procedural for-loop version with no instances.

module top_module( 
    input [99:0] a, b,
    input cin,
    output [99:0] cout,
    output [99:0] sum );

    // Carry into each stage: stage 0 gets cin, stage i gets cout[i-1].
    wire [99:0] carry_in = {cout[98:0], cin};

    genvar i;
    generate
        for (i = 0; i < 100; i = i + 1) begin : fa_chain
            fa u_fa (
                .a    (a[i]),
                .b    (b[i]),
                .cin  (carry_in[i]),
                .cout (cout[i]),
                .sum  (sum[i])
            );
        end
    endgenerate

endmodule

// Full adder (same cell as Adder3).
module fa(
    input a, b, cin,
    output cout, sum );

    assign {cout, sum} = a + b + cin;

endmodule
