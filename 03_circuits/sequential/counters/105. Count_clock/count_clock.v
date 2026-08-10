module top_module (
    input clk,
    input reset,
    input ena,
    output reg pm,
    output reg [7:0] hh,
    output reg [7:0] mm,
    output reg [7:0] ss
);
    always @ (posedge clk) begin
        if (reset) begin
            // Synchronous reset: 12:00:00 AM. hh is BCD-packed, so
            // "12" is nibbles (1,2) = 8'h12, not 8'h00.
            ss <= 8'h00;
            mm <= 8'h00;
            hh <= 8'h12;
            pm <= 1'b0;
        end
        else if (ena) begin

            // --- SECONDS ---
            if (ss[3:0] == 4'd9) begin
                ss[3:0] <= 4'd0;
                if (ss[7:4] == 4'd5) begin          // seconds tens wraps at 5 (0-59), not 9
                    ss[7:4] <= 4'd0;

                    // --- MINUTES (advances when seconds roll 59 -> 00) ---
                    if (mm[3:0] == 4'd9) begin
                        mm[3:0] <= 4'd0;
                        if (mm[7:4] == 4'd5) begin  // minutes tens also wraps at 5
                            mm[7:4] <= 4'd0;

                            // --- HOURS & AM/PM (advances when minutes roll 59 -> 00) ---
                            if (hh == 8'h12) begin
                                hh <= 8'h01;         // 12 -> 1, no "00" state, pm unchanged
                            end
                            else if (hh == 8'h11) begin
                                hh <= 8'h12;         // 11 -> 12, and this is the only AM/PM boundary
                                pm <= ~pm;
                            end
                            else if (hh[3:0] == 4'd9) begin
                                hh[3:0] <= 4'd0;     // 09 -> 10 (ones wraps, tens increments)
                                hh[7:4] <= 4'd1;
                            end
                            else begin
                                hh[3:0] <= hh[3:0] + 4'd1;  // ordinary +1 (1-8, 10 -> 11)
                            end

                        end
                        else begin
                            mm[7:4] <= mm[7:4] + 4'd1;
                        end
                    end
                    else begin
                        mm[3:0] <= mm[3:0] + 4'd1;
                    end

                end
                else begin
                    ss[7:4] <= ss[7:4] + 4'd1;
                end
            end
            else begin
                ss[3:0] <= ss[3:0] + 4'd1;
            end

        end
    end
endmodule
