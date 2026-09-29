// HDLBits: Alwaysblock2
// https://hdlbits.01xz.net/wiki/Alwaysblock2
//
// The directive below is part of HDLBits's provided header. It makes the tool
// parse this file as Verilog-2001, so the net-vs-variable rule is enforced here.

// synthesis verilog_input_version verilog_2001
module top_module(
    input clk,
    input a,
    input b,
    output wire out_assign,        // continuous assign             -> net
    output reg  out_always_comb,   // combinational always block    -> variable
    output reg  out_always_ff   ); // clocked always block          -> variable

    // 1. Continuous assignment: an XOR gate
    assign out_assign = a ^ b;

    // 2. Combinational always block: the same XOR gate.
    //    Blocking `=` for combinational logic.
    always @ (*) out_always_comb = a ^ b;

    // 3. Clocked always block: an XOR gate followed by a D flip-flop.
    //    Non-blocking `<=` for clocked logic. Output lags by one cycle.
    always @ (posedge clk) out_always_ff <= a ^ b;

endmodule
