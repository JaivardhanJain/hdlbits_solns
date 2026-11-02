// HDLBits: Conditional
// https://hdlbits.01xz.net/wiki/Conditional
//
// 4-way unsigned minimum built from three 2-way min circuits (?:).

module top_module (
    input [7:0] a, b, c, d,
    output [7:0] min);

    wire [7:0] t1, t2;

    assign t1  = a  < b ? a  : b;   // min(a, b)
    assign t2  = t1 < c ? t1 : c;   // min(a, b, c)
    assign min = t2 < d ? t2 : d;   // min(a, b, c, d)

endmodule
