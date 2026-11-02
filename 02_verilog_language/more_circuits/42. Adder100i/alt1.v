// HDLBits: Adder100i -- alternative
// https://hdlbits.01xz.net/wiki/Adder100i
//
// Same ripple-carry adder written as a procedural for loop. Builds the
// same circuit but contains no full-adder instances.
// Note: cout and sum are assigned procedurally, so portable code needs
// output reg / output logic; HDLBits accepts the bare header.

module top_module( 
    input [99:0] a, b,
    input cin,
    output [99:0] cout,
    output [99:0] sum );

    always @(*) begin
        {cout[0], sum[0]} = a[0] + b[0] + cin;           // stage 0 uses cin
        for (int i = 1; i < 100; i++) begin
            {cout[i], sum[i]} = a[i] + b[i] + cout[i-1];
        end
    end

endmodule
