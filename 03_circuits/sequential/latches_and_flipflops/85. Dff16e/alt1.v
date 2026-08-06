// Same circuit, with the redundant `else q <= q;` hold branches dropped.
// In a clocked always block, "no assignment" already means "hold" — the
// flip-flop keeps its value by construction. See README for why this does
// NOT infer a latch.
module alt1 (
    input clk,
    input resetn,               // synchronous, active-low reset
    input [1:0] byteena,
    input [15:0] d,
    output reg [15:0] q
);
    always @ (posedge clk) begin
        if (~resetn) q <= 16'b0;
        else begin
            if (byteena[1]) q[15:8] <= d[15:8];
            if (byteena[0]) q[7:0]  <= d[7:0];
        end
    end

endmodule
