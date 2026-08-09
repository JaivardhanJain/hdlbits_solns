module top_module (
    input clk,
    input x,
    output z
);
    wire t0, t1, t2, t3, t4, t5, t6, t7;

    my_dff dff0 (.clk(clk), .d(t0), .q(t1), .notq());
    my_dff dff1 (.clk(clk), .d(t2), .q(t3), .notq(t4));
    my_dff dff2 (.clk(clk), .d(t5), .q(t6), .notq(t7));

    assign z  = ~(t1 | t3 | t6);
    assign t0 = x ^ t1;
    assign t2 = x & t4;
    assign t5 = x | t7;

endmodule

module my_dff (
    input clk,
    input d,
    output reg q,
    output reg notq
);
    // Reset the pair at the source, so q/notq are true complements
    // even before the first clock edge — see README.
    initial begin
        q    = 1'b0;
        notq = 1'b1;
    end

    always @ (posedge clk) begin
        q    <= d;
        notq <= ~d;
    end
endmodule
