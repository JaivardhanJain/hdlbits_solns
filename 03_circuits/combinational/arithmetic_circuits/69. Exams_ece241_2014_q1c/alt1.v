// Alternative: the same sign-comparison logic written as a boolean
// equation instead of a nested ternary. "Signs of a and b match, AND
// the result's sign doesn't match theirs" is exactly the overflow
// condition, with no branching needed to express it.
module alt1 (
    input [7:0] a,
    input [7:0] b,
    output [7:0] s,
    output overflow
);

    assign s = a + b;
    assign overflow = ~(a[7] ^ b[7]) & (a[7] ^ s[7]);

endmodule
