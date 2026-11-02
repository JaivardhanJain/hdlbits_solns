// HDLBits: Reduction
// https://hdlbits.01xz.net/wiki/Reduction
//
// Even parity bit for one byte: XOR of all 8 data bits.

module top_module (
    input [7:0] in,
    output parity);

    assign parity = ^in;   // reduction XOR: in[7] ^ in[6] ^ ... ^ in[0]

endmodule
