// UART-style serial receiver: 1 start bit (0), 8 data bits, 1 stop bit (1); idle = 1.
// done pulses the cycle after a correct stop bit. A bad stop bit discards the byte
// and waits for the line to return to 1 before looking for the next start bit.
module top_module(
    input clk,
    input in,
    input reset,    // Synchronous reset
    output done
);

    parameter IDLE = 0, DATA = 1, STOP = 2, VALID = 3, INVALID = 4;
    logic [3:0] state, next_state;
    logic [7:0] counter = 0;

    // Next-state logic
    always_comb begin
        case(state)
            IDLE: next_state = in ? IDLE : DATA;
            DATA: next_state = counter >= 7 ? STOP : DATA;
            STOP: next_state = in ? VALID : INVALID;
            VALID: next_state = in ? IDLE : DATA;
            INVALID: next_state = in ? IDLE: INVALID;
            default: next_state = IDLE;
        endcase
    end

    // Sequential logic: state register + data-bit counter
    always_ff @ (posedge clk) begin
        if (reset) begin
            state <= IDLE;
            counter = 0;
        end
        else begin
            state <= next_state;
            if (state == DATA) counter = counter + 1;
            else counter = 0;
        end
    end

    // Output logic (Moore)
    assign done = state == VALID;

endmodule
