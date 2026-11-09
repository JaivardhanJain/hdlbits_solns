// Two-state Moore FSM (a JK flip-flop) with asynchronous reset to OFF.
// OFF: out = 0, go to ON on j=1, else stay.
// ON:  out = 1, go to OFF on k=1, else stay.
module top_module(
    input clk,
    input areset,    // Asynchronous reset to OFF
    input j,
    input k,
    output out);

    parameter OFF=0, ON=1;
    reg state, next_state;

    always_comb begin
        // State transition logic
        case(state)
            OFF: next_state = j ? ON : OFF;
            ON:  next_state = k ? OFF : ON;
        endcase
    end

    always @(posedge clk, posedge areset) begin
        // State flip-flops with asynchronous reset
        if (areset) begin
            state <= OFF;
        end
        else state <= next_state;
    end

    // Output logic (Moore: depends on state only)
    assign out = state === ON;

endmodule
