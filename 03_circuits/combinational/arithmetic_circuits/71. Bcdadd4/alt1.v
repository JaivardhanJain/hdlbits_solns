// Alternative: the same 4-digit chain built with a generate-for loop
// instead of 4 hand-written instances. Scales to more digits by
// changing one number instead of copy-pasting another instance.
module alt1 (
    input [15:0] a, b,
    input cin,
    output cout,
    output [15:0] sum );

    wire carry[4:0];
    assign carry[0] = cin;

    genvar i;
    generate
        for (i = 0; i < 4; i++) begin : bcd_gen_loop
            bcd_fadd bcd_fa(
                .a(a[i*4 +:4]),
                .b(b[i*4 +:4]),
                .cin(carry[i]),
                .cout(carry[i+1]),
                .sum(sum[i*4 +:4])
            );
        end
    endgenerate

    assign cout = carry[4];

endmodule
