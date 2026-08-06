module top_module (
    input clk,
    input L,
    input r_in,
    input q_in,
    output reg Q
);

    reg d;                  // must be reg, not wire — assigned procedurally below

    // Sequential: the flip-flop itself
    always @ (posedge clk) begin
        Q <= d;
    end

    // Combinational: the 2-to-1 mux feeding D
    always @ (*) begin
        case (L)
            1'b0    : d = q_in;
            default : d = r_in;
        endcase
    end

endmodule
