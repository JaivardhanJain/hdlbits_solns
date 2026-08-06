module top_module (
    input [15:0] a, b,
    input cin,
    output cout,
    output [15:0] sum );

    wire c [2:0];

    bcd_fadd my_adder0(.a(a[3:0]),   .b(b[3:0]),   .cin(cin),  .cout(c[0]), .sum(sum[3:0]));
    bcd_fadd my_adder1(.a(a[7:4]),   .b(b[7:4]),   .cin(c[0]), .cout(c[1]), .sum(sum[7:4]));
    bcd_fadd my_adder2(.a(a[11:8]),  .b(b[11:8]),  .cin(c[1]), .cout(c[2]), .sum(sum[11:8]));
    bcd_fadd my_adder3(.a(a[15:12]), .b(b[15:12]), .cin(c[2]), .cout(cout), .sum(sum[15:12]));

endmodule
