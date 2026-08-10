module top_module (
    input clk,
    input slowena,
    input reset,             // Synchronous active-high reset
    output reg [3:0] q
);
    always @ (posedge clk) begin
        if (reset)               q <= 4'd0;
        else if (slowena) begin
            if (q == 4'd9)        q <= 4'd0;
            else                  q <= q + 4'd1;
        end
        // slowena == 0: no assignment, q holds its value
    end

endmodule
