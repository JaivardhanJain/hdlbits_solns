// HDLBits: Vector100r
// https://hdlbits.01xz.net/wiki/Vector100r
//
// Reverse a 100-bit vector with a procedural for loop (SystemVerilog).
// See alt1.v for the generate-for version.

module top_module(
    input [99:0] in,
    output [99:0] out
);

    always_comb begin
        for (int i = 0; i < 100; i++) begin
            out[99 - i] = in[i];
        end
    end

endmodule
