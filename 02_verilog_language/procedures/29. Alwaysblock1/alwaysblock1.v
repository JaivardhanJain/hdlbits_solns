// HDLBits: Alwaysblock1
// https://hdlbits.01xz.net/wiki/Alwaysblock1
//
// The directive below is part of HDLBits's provided header. It makes the tool
// parse this file as Verilog-2001, so the net-vs-variable rule is enforced here.

// synthesis verilog_input_version verilog_2001
module top_module(
    input a,
    input b,
    output wire out_assign,       // driven by a continuous assign -> net
    output reg  out_alwaysblock   // assigned inside an always block -> variable
);

    // Style 1: continuous assignment
    assign out_assign = a & b;

    // Style 2: combinational always block. Same AND gate, same hardware.
    // `reg` is a declaration rule here, not a flip-flop.
    always @ (*)
        out_alwaysblock = a & b;

endmodule
