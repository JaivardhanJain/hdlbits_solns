// bcdcount is provided by HDLBits and instantiated, not redefined here:
// module bcdcount (
//     input clk,
//     input reset,
//     input enable,
//     output reg [3:0] Q
// );

module top_module (
    input clk,
    input reset,
    output OneHertz,
    output [2:0] c_enable
);

    // Three BCD digits: Q[0] = ones, Q[1] = tens, Q[2] = hundreds.
    wire [3:0] Q [2:0];

    assign c_enable[0] = 1'b1;                          // ones digit: always counts
    assign c_enable[1] = (Q[0] == 4'd9);                // tens digit: counts when ones is about to roll over
    assign c_enable[2] = (Q[1] == 4'd9) && c_enable[1];  // hundreds digit: counts when tens is about to roll over too
    assign OneHertz     = (Q[2] == 4'd9) && (Q[1] == 4'd9) && (Q[0] == 4'd9); // pulses for the one cycle the count reads 999

    bcdcount counter0 (.clk(clk), .reset(reset), .enable(c_enable[0]), .Q(Q[0]));
    bcdcount counter1 (.clk(clk), .reset(reset), .enable(c_enable[1]), .Q(Q[1]));
    bcdcount counter2 (.clk(clk), .reset(reset), .enable(c_enable[2]), .Q(Q[2]));

endmodule
