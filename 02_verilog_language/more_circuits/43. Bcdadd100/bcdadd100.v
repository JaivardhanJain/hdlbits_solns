// HDLBits: Bcdadd100
// https://hdlbits.01xz.net/wiki/Bcdadd100
//
// 100-digit BCD ripple-carry adder: 100 instances of the provided bcd_fadd,
// one per 4-bit digit. Digit 0 is instantiated by hand (it takes cin);
// digits 1-99 come from the generate loop, which steps i in bits (4, 8, ... 396).
//
// bcd_fadd is provided by HDLBits (not included here):
//   module bcd_fadd (
//       input [3:0] a,
//       input [3:0] b,
//       input     cin,
//       output   cout,
//       output [3:0] sum );

module top_module( 
    input [399:0] a, b,
    input cin,
    output cout,
    output [399:0] sum );

    wire [99:0] carry;   // carry[d] = carry-out of digit d

    bcd_fadd inst1(
       .a(a[3:0]),
       .b(b[3:0]),
       .cin(cin),
       .cout(carry[0]),
       .sum(sum[3:0])
    );

    genvar i;
    generate
        for (i = 4; i < 400; i += 4) begin : bcd_loop   // i = bit offset of digit i/4
            bcd_fadd inst (
                .a   (a[i +: 4]),
                .b   (b[i +: 4]),
                .cin (carry[i/4 - 1]),
                .cout(carry[i/4]),
                .sum (sum[i +: 4])
            );
        end
    endgenerate

    assign cout = carry[99];

endmodule
