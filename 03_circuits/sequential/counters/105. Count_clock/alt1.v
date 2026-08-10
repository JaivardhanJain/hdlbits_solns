// Structural alternative: one reusable, load-capable BCD digit building
// block (mod-10 by default, like count4 crossed with countbcd's
// bcdcounter), instantiated six times -- one per digit of ss, mm, hh --
// with a synchronous parameter to set each digit's reset value, and a
// load pin used only for the two places a digit's rollover ISN'T a plain
// mod-10 wrap: seconds/minutes tens (wraps at 5, not 9) and the hour
// field's 12 -> 1 jump (not expressible as any single digit hitting 9).
module bcdcounter_ld #(
    parameter [3:0] RESET_VAL = 4'd0
) (
    input clk,
    input reset,
    input enable,
    input load,
    input [3:0] d,
    output reg [3:0] Q
);
    always @ (posedge clk) begin
        if (reset)        Q <= RESET_VAL;
        else if (load)    Q <= d;              // load beats enable, same priority as count4
        else if (enable) begin
            if (Q == 4'd9) Q <= 4'd0;           // default digit behaviour: plain mod-10
            else           Q <= Q + 4'd1;
        end
    end
endmodule


module top_module (
    input clk,
    input reset,
    input ena,
    output reg pm,
    output [7:0] hh,
    output [7:0] mm,
    output [7:0] ss
);

    wire [3:0] ss_ones, ss_tens, mm_ones, mm_tens, hh_ones, hh_tens;
    assign ss = {ss_tens, ss_ones};
    assign mm = {mm_tens, mm_ones};
    assign hh = {hh_tens, hh_ones};

    // --- Seconds: ones is a plain mod-10 digit; tens wraps at 5 (0-59) ---
    wire ss_ones_carry = ena && (ss_ones == 4'd9);          // ones about to wrap this tick
    wire ss_tens_at5    = (ss_tens == 4'd5);
    wire ss_tens_load    = ss_ones_carry && ss_tens_at5;      // 59 -> 00: force tens back to 0
    wire ss_tens_ena     = ss_ones_carry && !ss_tens_at5;     // normal +1 (0-4 -> 1-5)
    wire ss_carry_out    = ss_ones_carry && ss_tens_at5;      // seconds field rolling 59 -> 00

    bcdcounter_ld #(.RESET_VAL(4'd0)) u_ss_ones (.clk(clk), .reset(reset), .enable(ena),         .load(1'b0),        .d(4'd0), .Q(ss_ones));
    bcdcounter_ld #(.RESET_VAL(4'd0)) u_ss_tens (.clk(clk), .reset(reset), .enable(ss_tens_ena),  .load(ss_tens_load), .d(4'd0), .Q(ss_tens));

    // --- Minutes: identical shape to seconds, gated by the seconds carry ---
    wire mm_ones_carry = ss_carry_out && (mm_ones == 4'd9);
    wire mm_tens_at5    = (mm_tens == 4'd5);
    wire mm_tens_load    = mm_ones_carry && mm_tens_at5;
    wire mm_tens_ena     = mm_ones_carry && !mm_tens_at5;
    wire mm_carry_out    = mm_ones_carry && mm_tens_at5;      // minutes field rolling 59 -> 00

    bcdcounter_ld #(.RESET_VAL(4'd0)) u_mm_ones (.clk(clk), .reset(reset), .enable(ss_carry_out), .load(1'b0),        .d(4'd0), .Q(mm_ones));
    bcdcounter_ld #(.RESET_VAL(4'd0)) u_mm_tens (.clk(clk), .reset(reset), .enable(mm_tens_ena),   .load(mm_tens_load), .d(4'd0), .Q(mm_tens));

    // --- Hours: irregular 1-12 range, no "00" state. The 09->10 carry is
    //     ordinary BCD ripple (handled for free by the mod-10 default);
    //     only the 12 -> 1 jump needs an explicit load override. ---
    wire hh_is_12       = (hh_tens == 4'd1) && (hh_ones == 4'd2);
    wire hh_is_11       = (hh_tens == 4'd1) && (hh_ones == 4'd1);
    wire hh_ones_carry  = mm_carry_out && (hh_ones == 4'd9);   // ordinary 09 -> 10 ripple condition
    wire hh_load         = mm_carry_out && hh_is_12;            // the one irregular transition
    wire hh_ones_load_val = 4'd1;                               // "12" -> "1": ones = 1
    wire hh_tens_load_val = 4'd0;                               //              tens = 0
    wire hh_ones_ena     = mm_carry_out && !hh_is_12;           // every other advance: plain +1/wrap
    wire hh_tens_ena     = hh_ones_carry && !hh_is_12;          // tens only moves on the 09->10 ripple

    bcdcounter_ld #(.RESET_VAL(4'd2)) u_hh_ones (.clk(clk), .reset(reset), .enable(hh_ones_ena), .load(hh_load), .d(hh_ones_load_val), .Q(hh_ones));
    bcdcounter_ld #(.RESET_VAL(4'd1)) u_hh_tens (.clk(clk), .reset(reset), .enable(hh_tens_ena), .load(hh_load), .d(hh_tens_load_val), .Q(hh_tens));

    // --- AM/PM toggles on exactly one transition: 11:59:59 -> 12:00:00 ---
    wire pm_toggle = mm_carry_out && hh_is_11;
    always @ (posedge clk) begin
        if (reset)          pm <= 1'b0;
        else if (pm_toggle) pm <= ~pm;
    end

endmodule
