// Alternate solution 1: one-hot, SystemVerilog, with named bit indices.
// A, B, C, D are bit INDICES into state (A = bit 0 = 4'b0001, ..., D = bit 3 = 4'b1000).
module top_module(
    input clk,
    input in,
    input areset,
    output out);

    parameter A = 0, B = 1, C = 2, D = 3;
    logic [3:0] state, next_state;

    // State transition logic: one equation per state bit, OR of its in-edges
    always_comb begin
        next_state[A] = ~in && (state[A] || state[C]);
        next_state[B] = in && (state[A] || state[B] || state[D]);
        next_state[C] = ~in && (state[B] || state[D]);
        next_state[D] = in && state[C];
    end

    // State flip-flops with asynchronous reset to A
    always_ff @ (posedge clk, posedge areset) begin
        if (areset) state = 4'b0001;
        else state <= next_state;
    end

    // Output logic (Moore: depends on state only)
    assign out = state[D];

endmodule
