// Approach 1: capture d in both a posedge and a negedge flop, then use
// clk itself to select which one is "fresh" right now.
//   clk=1 -> we just had a posedge -> t0 holds the newest value
//   clk=0 -> we just had a negedge -> t1 holds the newest value
// See README for the mux-select subtlety and why this is the more
// intuitive but also more fragile of the two approaches.
module top_module (
    input clk,
    input d,
    output q
);
    reg t0, t1;

    always @ (posedge clk) begin
        t0 <= d;
    end

    always @ (negedge clk) begin
        t1 <= d;
    end

    assign q = clk ? t0 : t1;
endmodule
