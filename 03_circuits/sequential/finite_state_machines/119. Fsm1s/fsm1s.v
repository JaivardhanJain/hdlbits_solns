// Two-state Moore FSM with synchronous reset to state B.
// B: out = 1, stay on in=1, go to A on in=0.
// A: out = 0, stay on in=1, go to B on in=0.
// Note the Verilog-1995 module declaration syntax (port list, then directions).
module top_module(clk, reset, in, out);
    input clk;
    input reset;    // Synchronous reset to state B
    input in;
    output out;
    reg out;

    parameter A = 0, B = 1;
    reg present_state, next_state;

    always @(posedge clk) begin
        if (reset) begin
            // Synchronous reset
            present_state = B;
        end else begin
            // State transition logic
            case (present_state)
                A: next_state = in ? A : B;
                B: next_state = in ? B: A;
            endcase

            // State flip-flops
            present_state <= next_state;
        end
    end

    // Output logic (Moore: depends on state only)
    assign out = present_state;

endmodule
