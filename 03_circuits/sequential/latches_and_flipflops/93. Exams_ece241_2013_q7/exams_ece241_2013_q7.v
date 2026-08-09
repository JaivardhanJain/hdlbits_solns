module top_module (
    input clk,
    input j,
    input k,
    output reg Q
);
    reg d;                  // must be reg, not wire — assigned procedurally below

    // Sequential: the flip-flop itself
    always @ (posedge clk) begin
        Q <= d;
    end

    // Combinational: JK truth table, translated into next-state logic for d
    always @ (*) begin
        case ({j, k})
            2'b00 : d = Q;
            2'b01 : d = 1'b0;
            2'b10 : d = 1'b1;
            2'b11 : d = ~Q;
        endcase
    end

endmodule
