// Water reservoir controller: 6-state Moore FSM with synchronous reset.
// s = {S3, S2, S1}; outputs fr3/fr2/fr1 are the nominal valves, dfr the supplemental one.
module top_module (
    input clk,
    input reset,
    input [3:1] s,
    output fr3,
    output fr2,
    output fr1,
    output dfr
);
    // RST  : below S1 (empty)            -> reset / low-for-long state
    // FLS1 : between S1 and S2, RISING
    // FLS2 : between S2 and S3, RISING
    // FLS3 : above S3 (full)
    // FH2  : between S2 and S3, FALLING
    // FH1  : between S1 and S2, FALLING
    parameter RST  = 3'b000, FLS1 = 3'b001, FLS2 = 3'b010,
              FLS3 = 3'b011, FH2  = 3'b100, FH1  = 3'b101;

    reg [2:0] state, next_state;

    // Next-state logic
    always @(*) begin
        next_state = state;              // default: hold (no latch)
        case (state)
            RST: case (s)
                    3'b000: next_state = RST;
                    3'b001: next_state = FLS1;
                    3'b011: next_state = FLS2;
                    3'b111: next_state = FLS3;
                  endcase
            FLS1: case (s)               // S1-S2, rising
                    3'b000: next_state = RST;
                    3'b001: next_state = FLS1;
                    3'b011: next_state = FLS2;
                  endcase
            FLS2: case (s)               // S2-S3, rising
                    3'b001: next_state = FH1;    // fell -> now falling
                    3'b011: next_state = FLS2;
                    3'b111: next_state = FLS3;
                  endcase
            FLS3: if (s[3]) next_state = FLS3;   // stay full
                  else      next_state = FH2;    // dropped -> falling
            FH2: case (s)                // S2-S3, falling
                    3'b000: next_state = RST;
                    3'b001: next_state = FH1;
                    3'b011: next_state = FH2;
                    3'b111: next_state = FLS3;
                  endcase
            FH1: case (s)                // S1-S2, falling
                    3'b000: next_state = RST;
                    3'b001: next_state = FH1;
                    3'b011: next_state = FLS2;    // rose -> now rising
                  endcase
            default: next_state = RST;
        endcase
    end

    // State register (synchronous reset)
    always @(posedge clk) begin
        if (reset) state <= RST;
        else       state <= next_state;
    end

    // Moore outputs (function of state only)
    assign fr1 = (state != FLS3);
    assign fr2 = (state == RST) || (state == FLS1) || (state == FH1);
    assign fr3 = (state == RST);
    assign dfr = (state == RST) || (state == FH2) || (state == FH1);
endmodule
