// Alternate solution 2: binary encoding (2 state bits) with a case statement.
// This is HDLBits's sample solution. Same circuit behaviour as fsm3.v (one-hot).
module top_module (
    input clk,
    input in,
    input areset,
    output out
);

    // State names and assignments. Any unique values work; decimal is simplest.
    parameter A=0, B=1, C=2, D=3;
    reg [1:0] state;    // Must be wide enough to hold every state encoding.
    reg [1:0] next;

    // Combinational always block for state transition logic (blocking assignments).
    always @(*) begin
        case (state)
            A: next = in ? B : A;
            B: next = in ? B : C;
            C: next = in ? D : A;
            D: next = in ? B : C;
        endcase
    end

    // Edge-triggered always block (DFFs) for state flip-flops. Asynchronous reset.
    always @(posedge clk, posedge areset) begin
        if (areset) state <= A;
        else state <= next;
    end

    // Combinational output logic (Moore: depends on state only).
    assign out = (state == D);

endmodule
