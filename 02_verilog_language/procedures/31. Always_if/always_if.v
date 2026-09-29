// HDLBits: Always_if
// https://hdlbits.01xz.net/wiki/Always_if
//
// The directive below is part of HDLBits's provided header. It makes the tool
// parse this file as Verilog-2001, so the net-vs-variable rule is enforced here.

// synthesis verilog_input_version verilog_2001
module top_module(
    input a,
    input b,
    input sel_b1,
    input sel_b2,
    output wire out_assign,
    output reg out_always   );

    // 2-to-1 mux: choose b only when BOTH selects are 1, otherwise a.

    // Style 1: continuous assign with the conditional operator.
    // && binds tighter than ?:, so this is (sel_b1 && sel_b2) ? b : a.
    assign out_assign = sel_b1 && sel_b2 ? b : a;

    // Style 2: if/else inside a combinational always block.
    // The else is what keeps this combinational: out_always is assigned
    // on every path, so no latch is inferred.
    always @ (*) begin
        if (sel_b1 && sel_b2) out_always = b;
        else                  out_always = a;
    end

endmodule
