// Alternative: derive sum and carry directly from binary addition
// instead of writing the XOR/AND boolean equations by hand.
module alt1(
    input a, b,
    output cout, sum );

    assign {cout, sum} = a + b;

endmodule
