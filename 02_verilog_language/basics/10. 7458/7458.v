// Best-practice solution: intermediate wires + assign.
// Named signals stay visible in waveform viewers and document the
// AND-AND-OR structure explicitly. This is the module HDLBits grades.
module top_module (
    input p1a, p1b, p1c, p1d, p1e, p1f,
    output p1y,
    input p2a, p2b, p2c, p2d,
    output p2y );

    wire t1, t2, t3, t4;

    assign t1  = p2a & p2b;
    assign t2  = p2c & p2d;
    assign p2y = t1  | t2;

    assign t3  = p1a & p1b & p1c;
    assign t4  = p1d & p1e & p1f;
    assign p1y = t3  | t4;

endmodule


// Alt 1: direct nested assign, no intermediate wires.
// Fine for short expressions like this one, but harder to read/debug
// as expressions grow, and intermediate values aren't visible in sim.
module alt1 (
    input p1a, p1b, p1c, p1d, p1e, p1f,
    output p1y,
    input p2a, p2b, p2c, p2d,
    output p2y );

    assign p1y = (p1a & p1b & p1c) | (p1d & p1e & p1f);
    assign p2y = (p2a & p2b) | (p2c & p2d);

endmodule


// Alt 2: gate-level primitives (structural modelling).
// Legacy/pedagogical style — real RTL describes behavior and lets the
// synthesis tool pick gates, rather than hand-instantiating them.
module alt2 (
    input p1a, p1b, p1c, p1d, p1e, p1f,
    output p1y,
    input p2a, p2b, p2c, p2d,
    output p2y );

    wire t1, t2, t3, t4;

    and(t1, p2a, p2b);
    and(t2, p2c, p2d);
    or(p2y, t1, t2);

    and(t3, p1a, p1b, p1c);
    and(t4, p1d, p1e, p1f);
    or(p1y, t3, t4);

endmodule
