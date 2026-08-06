// Same circuit collapsed into one clocked block, two nested ternaries
// standing in for the two muxes. No intermediate wires needed.
module alt1 (
    input clk,
    input w, R, E, L,
    output reg Q
);
    always @ (posedge clk) begin
        Q <= L ? R : (E ? w : Q);
    end

endmodule
