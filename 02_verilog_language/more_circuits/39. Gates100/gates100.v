// HDLBits: Gates100
// https://hdlbits.01xz.net/wiki/Gates100
//
// 100-input AND, OR and XOR using reduction operators.

module top_module(
    input [99:0] in,
    output out_and,
    output out_or,
    output out_xor
);

    assign out_and = &in;   // 1 only if all 100 bits are 1
    assign out_or  = |in;   // 1 if any bit is 1
    assign out_xor = ^in;   // 1 if an odd number of bits are 1

endmodule
