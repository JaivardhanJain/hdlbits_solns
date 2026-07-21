// Behavioural alternative: describe *what* the circuit computes
// (a 4-bit add whose result needs 5 bits) instead of *how* it's built
// out of four chained full adders.
module alt1 (
    input [3:0] x,
    input [3:0] y,
    output [4:0] sum);

    assign sum = x + y;

endmodule
