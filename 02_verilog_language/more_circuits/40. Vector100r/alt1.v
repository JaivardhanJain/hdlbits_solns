// HDLBits: Vector100r -- alternative
// https://hdlbits.01xz.net/wiki/Vector100r
//
// Reverse a 100-bit vector with a generate-for loop: the loop stamps out
// 100 continuous assignments at compile time, so out stays a plain net.

module top_module(
    input [99:0] in,
    output [99:0] out
);

    genvar i;
    generate
        for (i = 0; i < 100; i = i + 1) begin : rev   // label is required by some tools
            assign out[i] = in[99 - i];
        end
    endgenerate

endmodule
