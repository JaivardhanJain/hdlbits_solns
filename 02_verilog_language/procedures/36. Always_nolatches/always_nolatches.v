// HDLBits: Always_nolatches
// https://hdlbits.01xz.net/wiki/Always_nolatches
//
// Decode the PS/2 arrow-key scancodes into four 1-bit outputs.
// Every output gets a default at the top of the block, so every path
// through the case assigns all four and no latch is inferred.

// synthesis verilog_input_version verilog_2001
module top_module (
    input [15:0] scancode,
    output reg left,
    output reg down,
    output reg right,
    output reg up  );

    always @(*) begin
        left = 1'b0; down = 1'b0; right = 1'b0; up = 1'b0;   // defaults
        case (scancode)
            16'he06b: left  = 1'b1;
            16'he072: down  = 1'b1;
            16'he074: right = 1'b1;
            16'he075: up    = 1'b1;
            // no default item needed: anything else keeps the 0s above
        endcase
    end

endmodule
