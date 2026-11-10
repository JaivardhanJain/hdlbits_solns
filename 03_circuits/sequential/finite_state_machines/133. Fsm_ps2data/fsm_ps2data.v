// PS/2 message framer + datapath: Fsm_ps2's FSM plus a 3-byte shift register.
// out_bytes = {byte1, byte2, byte3}, valid in the cycle done is high.
module top_module(
    input clk,
    input [7:0] in,
    input reset,    // Synchronous reset
    output [23:0] out_bytes,
    output done);

    logic [23:0] out;
    parameter rst = 2'b00, got1 = 2'b01, got2 = 2'b10, got3 = 2'b11;
    logic [1:0] state, next_state;

    // State transition logic (combinational)
    always_comb begin
        case (state)
            rst: if (in[3]) next_state = got1;
                 else next_state = rst;
            got1: next_state = got2;
            got2: next_state = got3;
            got3: if (in[3]) next_state = got1;
                 else next_state = rst;
            default: next_state = rst;
        endcase
    end

    // State flip-flops (sequential)
    always_ff @ (posedge clk) begin
        if (reset) state <= rst;
        else state <= next_state;
    end

    // Output logic
    assign done = (state === got3);

    // Datapath: shift every incoming byte into a 3-byte window (oldest at the top)
    always_ff @ (posedge clk) begin
        out[23:8] = out[15:0];
        out[7:0] = in;
    end

    assign out_bytes = done ? out : 24'b0;

endmodule
