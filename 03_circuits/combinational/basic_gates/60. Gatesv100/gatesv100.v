module top_module (
    input [99:0] in,
    output [98:0] out_both,
    output [99:1] out_any,
    output [99:0] out_different
);

    // Same three assigns as Gatesv, just re-declared over 100-bit ports.
    // Nothing in the assign statements themselves needed to change.
    assign out_any       = in[99:1] | in[98:0];
    assign out_both      = in[98:0] & in[99:1];

    // XOR 'in' with a copy of itself rotated right by 1: {in[0], in[99:1]}
    assign out_different = in ^ {in[0], in[99:1]};

endmodule
