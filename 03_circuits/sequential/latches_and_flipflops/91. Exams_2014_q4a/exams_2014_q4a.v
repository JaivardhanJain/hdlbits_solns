module top_module (
    input clk,
    input w, R, E, L,
    output reg Q
);
    reg t, d;                // must be reg, not wire — assigned procedurally below

    // Sequential: the flip-flop itself
    always @ (posedge clk) begin
        Q <= d;
    end

    // Combinational: enable mux (t) feeding the load mux (d)
    always @ (*) begin
        t = E ? w : Q;
        d = L ? R : t;
    end

endmodule
