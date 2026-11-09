// Two-state Moore FSM with asynchronous reset to state B.
// B: out = 1, stay on in=1, go to A on in=0.
// A: out = 0, stay on in=1, go to B on in=0.
module top_module(
    input clk,
    input areset,    // Asynchronous reset to state B
    input in,
    output out);

    parameter A=0, B=1;
    reg state, next_state;

    always_comb begin    // Combinational: next-state logic
        case(state)
            A: next_state = in ? A : B;
            B: next_state = in ? B : A;
        endcase
    end

    always_ff @(posedge clk, posedge areset) begin    // Sequential: state flip-flop
        if (areset) state <= B;
        else state <= next_state;
    end

    // Output logic (Moore: depends on state only)
    assign out = state === B;

endmodule
