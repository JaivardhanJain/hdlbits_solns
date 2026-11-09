// Next-state and output logic for a 4-state Moore FSM, one-hot encoded.
// Encoding: A=4'b0001, B=4'b0010, C=4'b0100, D=4'b1000. out = 1 only in D.
// A, B, C, D below are bit INDICES into state, not state values.
module top_module(
    input in,
    input [3:0] state,
    output [3:0] next_state,
    output out);

    parameter A=0, B=1, C=2, D=3;

    // State transition logic: one equation per state flip-flop,
    // OR-ing together every in-edge of that state.
    assign next_state[A] = state[A] & ~in || state[C] & ~in;
    assign next_state[B] = in && (state[A] || state[B] || state[D]);
    assign next_state[C] = ~in && (state[B] || state[D]);
    assign next_state[D] = state[C] && in;

    // Output logic (Moore: depends on state only)
    assign out = state[D];

endmodule
