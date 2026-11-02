// HDLBits: Popcount255
// https://hdlbits.01xz.net/wiki/Popcount255
//
// Population count: out = number of 1 bits in in[254:0].
// 255 inputs -> max count 255, which fits exactly in 8 bits.

module top_module(
    input [254:0] in,
    output [7:0] out );

    always @(*) begin
        out = 0;                          // must reset before accumulating
        for (int i = 0; i < 255; i++) begin
            if (in[i] == 1) out += 1;
        end
    end

endmodule
