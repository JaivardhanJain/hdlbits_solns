// HDLBits: Always_if2
// https://hdlbits.01xz.net/wiki/Always_if2
//
// HDLBits gives a buggy version of this module in which both always blocks
// have an `if` with no `else`, so each output infers a latch. The fix is an
// `else` in each block, which assigns every output on every path.

// synthesis verilog_input_version verilog_2001
module top_module (
    input      cpu_overheated,
    output reg shut_off_computer,
    input      arrived,
    input      gas_tank_empty,
    output reg keep_driving  );

    always @(*) begin
        if (cpu_overheated)
           shut_off_computer = 1;
        else
           shut_off_computer = 0;   // added: without it, the output latches at 1
    end

    always @(*) begin
        if (~arrived)
           keep_driving = ~gas_tank_empty;
        else
           keep_driving = 1'b0;     // added: stop once we've arrived
    end

endmodule
