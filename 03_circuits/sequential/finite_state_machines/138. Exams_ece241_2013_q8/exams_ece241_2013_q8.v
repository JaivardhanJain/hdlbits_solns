// Mealy FSM detecting "101" on x (overlapping), 3 states, async active-low reset.
// RST: no useful prefix;  GOT1: seen "1";  GOT10: seen "10".  z = 1 when in GOT10 and x = 1.
module top_module (
    input clk,
    input aresetn,    // Asynchronous active-low reset
    input x,
    output z );

    parameter RST = 0, GOT1 = 1, GOT10 = 2;
    logic [2:0] state, next_state;

    // Next-state logic
    always_comb begin
        case(state)
            RST: next_state = x ? GOT1 : RST;
            GOT1: next_state = x ? GOT1 : GOT10;
            GOT10: next_state = x ? GOT1 : RST;
        endcase
    end

    // Sequential logic
    always_ff @ (posedge clk, negedge aresetn) begin
        if (~aresetn) state <= RST;
        else state <= next_state;
    end

    // Output logic (Mealy: depends on state AND input)
    assign z = (state == GOT10) && x;

endmodule
