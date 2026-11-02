// HDLBits: Always_case2
// https://hdlbits.01xz.net/wiki/Always_case2
//
// 4-bit priority encoder: pos = index of the lowest set bit of in.
// in = 0 outputs 0.

// synthesis verilog_input_version verilog_2001
module top_module (
    input [3:0] in,
    output reg [1:0] pos  );

    always @(*) begin           // Combinational always block
        case (in)
            4'h0: pos = 2'h0;   // Hexadecimal saves typing vs. binary.
            4'h1: pos = 2'h0;
            4'h2: pos = 2'h1;
            4'h3: pos = 2'h0;
            4'h4: pos = 2'h2;
            4'h5: pos = 2'h0;
            4'h6: pos = 2'h1;
            4'h7: pos = 2'h0;
            4'h8: pos = 2'h3;
            4'h9: pos = 2'h0;
            4'ha: pos = 2'h1;
            4'hb: pos = 2'h0;
            4'hc: pos = 2'h2;
            4'hd: pos = 2'h0;
            4'he: pos = 2'h1;
            4'hf: pos = 2'h0;
            default: pos = 2'b0;    // Not strictly necessary: all 16 combinations are covered.
        endcase
    end

    // There is an easier way to code this. See the next problem (Always_casez).

endmodule
