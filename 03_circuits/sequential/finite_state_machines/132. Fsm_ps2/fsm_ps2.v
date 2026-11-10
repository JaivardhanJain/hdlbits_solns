// PS/2 message framer: find 3-byte messages in a byte stream (byte 1 has in[3]=1).
// RST  : searching for byte 1 (discarding bytes with in[3]=0)
// REQ1 : byte 1 received;  REQ2 : byte 2 received;  REQ3 : byte 3 received, done=1
module top_module(
    input clk,
    input [7:0] in,
    input reset,    // Synchronous reset
    output done);

    parameter RST = 0, REQ1 = 1, REQ2 = 2, REQ3 = 3;
    logic [1:0] state, next_state;

    // State transition logic (combinational)
    always_comb begin
        case(state)
            RST: next_state = in[3] ? REQ1 : RST;
            REQ1: next_state = REQ2;
            REQ2: next_state = REQ3;
            REQ3: begin
                next_state = in[3] ? REQ1 : RST;   // back-to-back message?
            end
        endcase
    end

    // State flip-flops (sequential)
    always_ff @ (posedge clk) begin
        if (reset) begin
            state <= RST;
        end
        else state <= next_state;
    end

    // Output logic (Moore: done for the one cycle after byte 3)
    assign done = state == REQ3;

endmodule
