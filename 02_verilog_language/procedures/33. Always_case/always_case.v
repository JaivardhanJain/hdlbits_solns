// HDLBits: Always_case
// https://hdlbits.01xz.net/wiki/Always_case
//
// 6-to-1 mux of 4-bit inputs. sel = 6 or 7 outputs 0.

// synthesis verilog_input_version verilog_2001
module top_module (
    input [2:0] sel,
    input [3:0] data0,
    input [3:0] data1,
    input [3:0] data2,
    input [3:0] data3,
    input [3:0] data4,
    input [3:0] data5,
    output reg [3:0] out   );

    always @(*) begin  // combinational: every path assigns out
        case (sel)
            3'b000:  out = data0;
            3'b001:  out = data1;
            3'b010:  out = data2;
            3'b011:  out = data3;
            3'b100:  out = data4;
            3'b101:  out = data5;
            default: out = 4'b0000;   // sel = 6, 7 (and x/z in simulation)
        endcase
    end

endmodule
