// Combinational half of a 4-state Moore FSM: next-state and output logic only.
// Encoding: A=2'b00, B=2'b01, C=2'b10, D=2'b11. out = 1 only in D.
module top_module(
    input in,
    input [1:0] state,
    output [1:0] next_state,
    output out);

    parameter A=0, B=1, C=2, D=3;

    // State transition logic: next_state = f(state, in)
    always_comb begin
        case(state)
            A: next_state = in ? B : A;
            B: next_state = in ? B : C;
            C: next_state = in ? D : A;
            D: next_state = in ? B : C;
        endcase
    end

    // Output logic: out = f(state) for a Moore state machine
    assign out = state == D;

endmodule
