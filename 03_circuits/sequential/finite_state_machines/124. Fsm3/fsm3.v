// 4-state Moore FSM with asynchronous reset to A, one-hot encoded.
// A=4'b0001 (bit 0), B=4'b0010 (bit 1), C=4'b0100 (bit 2), D=4'b1000 (bit 3).
// out = 1 only in D.
module top_module(
    input clk,
    input in,
    input areset,
    output out);

    reg [3:0] state, next_state;
    parameter A = 4'b0001, B = 4'b0010, C = 4'b0100, D = 4'b1000;

    // State transition logic: one equation per state bit, OR of its in-edges
    always @ (*) begin
        next_state[0] = state[0] & ~in | state[2] & ~in;
        next_state[1] = state[0] &  in | state[1] &  in | state[3] & in;
        next_state[2] = state[1] & ~in | state[3] & ~in;
        next_state[3] = state[2] &  in;
    end

    // State flip-flops with asynchronous reset
    always @ (posedge clk, posedge areset) begin
        if (areset) state <= A;
        else state <= next_state;
    end

    // Output logic (Moore: depends on state only)
    assign out = state[3];

endmodule
