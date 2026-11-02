// HDLBits: Always_casez
// https://hdlbits.01xz.net/wiki/Always_casez
//
// 8-bit priority encoder: pos = index of the lowest set bit of in.
// in = 0 outputs 0.
//
// Each item pins the lowest set bit AND every bit below it to 0, so no two
// items can match the same input. Item order doesn't matter.

// synthesis verilog_input_version verilog_2001
module top_module (
    input [7:0] in,
    output reg [2:0] pos );

    always @(*) begin
        casez (in)
            8'b10000000: pos = 3'b111;
            8'b?1000000: pos = 3'b110;
            8'b??100000: pos = 3'b101;
            8'b???10000: pos = 3'b100;
            8'b????1000: pos = 3'b011;
            8'b?????100: pos = 3'b010;
            8'b??????10: pos = 3'b001;
            8'b???????1: pos = 3'b000;
            default:     pos = 3'b000;   // in = 0
        endcase
    end

endmodule
