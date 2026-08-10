module top_module (
    input clk,
    input reset,       // Synchronous active-high reset
    output [3:1] ena,
    output [15:0] q
);

    assign ena[1] = (q[3:0]  == 4'd9);
    assign ena[2] = (q[3:0]  == 4'd9) && (q[7:4]  == 4'd9);
    assign ena[3] = (q[3:0]  == 4'd9) && (q[7:4]  == 4'd9) && (q[11:8] == 4'd9);

    bcdcounter counter0 (.clk(clk), .reset(reset), .enable(1'b1),   .Q(q[3:0]));
    bcdcounter counter1 (.clk(clk), .reset(reset), .enable(ena[1]), .Q(q[7:4]));
    bcdcounter counter2 (.clk(clk), .reset(reset), .enable(ena[2]), .Q(q[11:8]));
    bcdcounter counter3 (.clk(clk), .reset(reset), .enable(ena[3]), .Q(q[15:12]));

endmodule


module bcdcounter (
    input clk,
    input reset,
    input enable,
    output reg [3:0] Q
);
    always @ (posedge clk) begin
        if (reset)          Q <= 4'd0;
        else if (enable) begin
            if (Q == 4'd9)   Q <= 4'd0;
            else             Q <= Q + 4'd1;
        end
    end
endmodule
