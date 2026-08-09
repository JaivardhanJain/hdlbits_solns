// Approach 2: two flops that each store "what q must become to cancel the
// other one out." No mux, no dependency on clk's current level to select
// a path — q is just p^n at all times. See README for the full derivation.
module alt1 (
    input clk,
    input d,
    output q
);
    reg p, n;

    // Positive-edge triggered flip-flop
    always @ (posedge clk)
        p <= d ^ n;

    // Negative-edge triggered flip-flop
    always @ (negedge clk)
        n <= d ^ p;

    // After posedge clk: p becomes d^n, so q = p^n = (d^n)^n = d.
    // After negedge clk: n becomes d^p, so q = p^n = p^(d^p) = d.
    // At each edge, whichever flop just updated loads a value that
    // cancels the other flop's stored value out of the XOR, leaving d.
    assign q = p ^ n;
endmodule
