// Alternative fix: instead of resetting notq at the source, never trust a
// separately-registered "complement" at all — derive it combinationally
// from q wherever it's needed. No initial block required anywhere.
// See README for the trade-off between the two approaches.
module alt1 (
    input clk,
    input x,
    output z
);
    wire t0, t1, t2, t3, t5, t6;

    my_dff dff0 (.clk(clk), .d(t0), .q(t1), .notq());
    my_dff dff1 (.clk(clk), .d(t2), .q(t3), .notq());
    my_dff dff2 (.clk(clk), .d(t5), .q(t6), .notq());

    assign z  = ~(t1 | t3 | t6);
    assign t0 = x ^ t1;
    assign t2 = x & ~t3;
    assign t5 = x | ~t6;

endmodule

module my_dff (
    input clk,
    input d,
    output reg q,
    output reg notq
);
    always @ (posedge clk) begin
        q    <= d;
        notq <= ~d;
    end
endmodule
