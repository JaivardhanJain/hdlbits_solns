module top_module (
    input clk,
    input [7:0] in,
    output reg [7:0] pedge
);
    reg [7:0] d_last;

    always @ (posedge clk) begin
        d_last <= in;           // remember this cycle's input for next cycle
        pedge  <= in & ~d_last; // bit was 0 last cycle, is 1 this cycle
    end

endmodule
