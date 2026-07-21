// Alternative: derive sum and carry from binary addition of all
// three inputs instead of writing the majority/XOR equations by hand.
module alt1(
    input a, b, cin,
    output cout, sum );

    assign {cout, sum} = a + b + cin;

endmodule
