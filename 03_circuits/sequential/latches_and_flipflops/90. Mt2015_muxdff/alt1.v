// Same circuit collapsed into a single clocked block. The mux becomes a
// ternary in the D expression — no intermediate signal, no second always
// block. Preferred when the next-state logic is this small.
module alt1 (
    input clk,
    input L,
    input r_in,
    input q_in,
    output reg Q
);
    always @ (posedge clk) begin
        Q <= L ? r_in : q_in;
    end

endmodule
