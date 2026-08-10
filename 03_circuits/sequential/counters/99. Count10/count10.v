module top_module (
    input clk,
    input reset,            // Synchronous active-high reset
    output reg [3:0] q
);
    always @ (posedge clk) begin
        if (reset)            q <= 4'd0;
        else if (q == 4'd9)   q <= 4'd0;   // terminal count: wrap early
        else                  q <= q + 4'd1;
    end

endmodule
