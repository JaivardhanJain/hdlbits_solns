module top_module (
    input [3:0] x,
    input [3:0] y,
    output [4:0] sum);

    wire t1, t2, t3;

    fa fa1 (
        x[0], y[0], 1'b0,
        t1, sum[0]
    );
    fa fa2 (
        x[1], y[1], t1,
        t2, sum[1]
    );
    fa fa3 (
        x[2], y[2], t2,
        t3, sum[2]
    );
    fa fa4 (
        x[3], y[3], t3,
        sum[4], sum[3]
    );

endmodule

module fa (
    input x, y, cin,
    output cout, sum);

    assign {cout, sum} = x + y + cin;

endmodule
