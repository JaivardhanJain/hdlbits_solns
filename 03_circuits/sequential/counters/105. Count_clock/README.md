# Count_clock

**HDLBits link:** https://hdlbits.01xz.net/wiki/count_clock
**Category:** Circuits: Sequential (Counters)
**Difficulty:** ⭐⭐⭐⭐⭐

## Problem summary

Build a 12-hour wall-clock counter: `hh` (01-12), `mm` (00-59), `ss` (00-59), each a two-BCD-digit byte, plus `pm` (0 = AM, 1 = PM). `clk` is a fast free-running clock; `ena` pulses once per real second, and the whole clock only advances on cycles where `ena` is high. `reset` is synchronous, forces 12:00:00 AM, and — critically — has priority over `ena` and can fire even on a cycle where `ena` is low. There is no `00:00:00` on a 12-hour clock: 11:59:59 → 12:00:00 (and toggles AM/PM), while 12:59:59 → 01:00:00 (no AM/PM change).

## Why this is the hardest counter in the chapter

Every earlier counter in this chapter had one uniform rollover rule applied to every digit: 0-9 wraps at 9, 0-5 wraps at 5, and so on, in a completely regular ripple-carry pattern. This problem has **three different rollover rules stacked on top of each other**: seconds and minutes are almost-ordinary two-digit BCD counters, except their *tens* digit wraps at 5, not 9 (there's no "6X" seconds). The hours field is worse — it isn't a modulo-anything counter at all. It's a 12-state cycle (1 through 12) with no zero, so its "wrap" isn't a digit hitting 9 and resetting; it's the *entire two-digit value* jumping from 12 straight to 1, which cannot be expressed as any single digit's simple increment-or-reset rule. On top of that, `pm` has to flip on exactly one of those twelve transitions (11→12) and stay put on all the others, including the 12→1 jump that looks superficially similar.

## Approach 1 — one big behavioural state machine (`count_clock.v`)

```verilog
always @ (posedge clk) begin
    if (reset) begin
        ss <= 8'h00; mm <= 8'h00; hh <= 8'h12; pm <= 1'b0;
    end
    else if (ena) begin
        if (ss[3:0] == 4'd9) begin
            ss[3:0] <= 4'd0;
            if (ss[7:4] == 4'd5) begin          // seconds tens wraps at 5
                ss[7:4] <= 4'd0;
                if (mm[3:0] == 4'd9) begin
                    mm[3:0] <= 4'd0;
                    if (mm[7:4] == 4'd5) begin  // minutes tens wraps at 5
                        mm[7:4] <= 4'd0;
                        if (hh == 8'h12)      hh <= 8'h01;              // 12 -> 1
                        else if (hh == 8'h11) begin hh <= 8'h12; pm <= ~pm; end  // 11 -> 12
                        else if (hh[3:0] == 4'd9) begin hh[3:0] <= 4'd0; hh[7:4] <= 4'd1; end // 09 -> 10
                        else                    hh[3:0] <= hh[3:0] + 4'd1;      // ordinary +1
                    end else mm[7:4] <= mm[7:4] + 4'd1;
                end else mm[3:0] <= mm[3:0] + 4'd1;
            end else ss[7:4] <= ss[7:4] + 4'd1;
        end else ss[3:0] <= ss[3:0] + 4'd1;
    end
end
```

This is a single ripple-carry cascade written out by hand, exactly like Countbcd's `bcdcounter` chain, except each carry condition is nested `if`/`else` instead of a separate combinational `enable` wire, and the outermost stage (hours) needs three special-cased branches instead of the usual "wraps at 9" rule. Reading it as a decision tree — "did seconds' ones digit just hit 9? did its tens digit also hit 5? did minutes' ones digit hit 9? did *its* tens digit hit 5? — only then does anything touch `hh`" — is the same nested-carry structure as a ripple-carry adder, just four levels deep instead of one.

## Approach 2 — six reusable, load-capable BCD digit counters (`alt1.v`)

The monolithic version above hand-writes the ripple-carry condition at every level. The structural alternative pulls the pattern out into one reusable building block — `bcdcounter_ld`, combining `count4`'s `load` input with Countbcd's mod-10 `bcdcounter` behaviour, plus a `RESET_VAL` **parameter** so the same module can reset to 0 (seconds, minutes, hour tens... no, hour tens resets to 1) or to a specific nonzero digit (hour ones resets to `2`, hour tens to `1`, since 12-in-BCD is nibbles `(1,2)`, not `(0,0)`):

```verilog
module bcdcounter_ld #(parameter [3:0] RESET_VAL = 4'd0) (
    input clk, reset, enable, load,
    input [3:0] d,
    output reg [3:0] Q
);
    always @ (posedge clk) begin
        if (reset)        Q <= RESET_VAL;
        else if (load)    Q <= d;
        else if (enable) begin
            if (Q == 4'd9) Q <= 4'd0;
            else           Q <= Q + 4'd1;
        end
    end
endmodule
```

This is instantiated **six times** — once per digit of `ss`, `mm`, `hh` — and the interesting design work moves from "write the right nested `if` chain" to "figure out, for each digit, what `enable` and `load` need to be":

- **Seconds/minutes ones digits** never need `load` — a plain mod-10 digit is exactly right, `enable`'d whenever the field beneath it (or `ena` itself, for the fastest digit) is advancing.
- **Seconds/minutes tens digits** wrap at 5, not the module's built-in 9 — so `load` is asserted (forcing `d = 0`) exactly when the ones digit is carrying *and* the tens digit is already at 5; otherwise the tens digit gets a plain `enable` and lets its own internal mod-10 rule do an ordinary +1.
- **Hour ones/tens** reuse the *same* module, but their `load` only fires on the one truly irregular transition (12 → 1); the 09 → 10 ripple is handled for free by the same "digit hits 9, carries into the next digit's enable" pattern used everywhere else, because — perhaps surprisingly — that transition (and 11 → 12) *are* ordinary BCD arithmetic. Only 12 → 1 needs the escape hatch.

`pm` is not one of the six digit counters — it's its own 1-bit register, toggled by a combinational `pm_toggle = mm_carry_out && hh_is_11`, computed exactly the same way in both files.

Which version is "better" depends on what you're optimizing for: the monolithic version is more compact and arguably easier to trace top-to-bottom as one narrative; the structural version tests one small, thoroughly-understood building block instead of one large bespoke state machine, and it's the shape a design would take if the seconds/minutes/hours counters needed to be swapped, reused elsewhere, or unit-tested independently — a real consideration once a "clock" stops being a homework problem and becomes one block among many in a larger chip.

## Gotchas / things to watch for

- **The `hh == 8'h11` branch's numeric effect is a plain `+1`, which makes it look mergeable with the generic `else` branch — but it can't be, because `pm` only toggles inside it.** Trace it: `hh=8'h11` is tens=1, ones=1; incrementing the ones digit by 1 (the "ordinary" rule) gives ones=2, i.e. `hh=8'h12` — the exact same numeric result the special-cased branch produces. It's tempting to conclude the `hh==8'h11` branch is redundant and could be deleted, letting the generic `else hh[3:0] <= hh[3:0]+1` handle it. Numerically, that's true. But the *only* place `pm` gets toggled is inside that branch — collapse it into the generic case and the hour still advances correctly, `pm` silently stops updating, and the bug won't show up until the very first noon-or-midnight crossing, which is 12 simulated hours (43,200 real seconds) into any test. This is the sharpest version of a lesson this repo keeps returning to: two branches computing the same *value* are not interchangeable if they have different *side effects*.

- **The `hh == 8'h12` check must run, and must run before any generic ones-digit increment logic, or the clock silently produces an invalid hour.** Without it, `hh = 8'h12` (tens=1, ones=2) would fall into the generic `else` branch, incrementing the ones digit to 3 and producing `hh = 8'h13` — "13 o'clock," a value that never legally exists on this clock and has no defined meaning downstream (a seven-segment decoder fed `4'd3` in the ones position would happily display it as if nothing were wrong). Because this only fires once every 12 hours, a testbench that runs for a few dozen simulated seconds will never exercise this path at all — it's exactly the kind of bug that survives a superficial test and ships.

- **Reusing Countbcd's `bcdcounter` (which wraps at 9) unmodified for the seconds/minutes tens digit.** It's the most natural first instinct — "I already have a working BCD digit counter, seconds are two BCD digits, done" — and it's wrong, because seconds and minutes only run 00-59: the *tens* digit's valid range is 0-5, not 0-9. A tens digit that wraps at 9 would let the seconds field count all the way to 99 before rolling over, silently breaking the 60-second minute. The ones digit genuinely is an ordinary mod-10 counter (0-9 every cycle, regardless of the tens value) — it's specifically the tens digit of a base-60 field that needs the different threshold, either via a `MAX` parameter or (as in `alt1.v`) a `load`-to-zero override once it reaches 5.

- **Writing the hour reset as `hh <= 8'h00` (or worse, `hh <= 0`) instead of `8'h12`.** The spec is explicit that there's no `00:00:00` state on a 12-hour clock — midnight is `12:00:00 AM`. Since `hh` is BCD-packed, "12" is the byte `8'h12` (nibbles 1 and 2), which looks unusually close to "the register's value happens to equal its own bit-pattern name" and invites a lazy `8'h00`-by-habit mistake, the same class of error flagged for Count1to10's mismatched reset/wrap pair, just with higher stakes here since it's wrong from the very first cycle rather than only after 12 hours.

- **In the structural version, forgetting that `hh_ones` and `hh_tens` need *different*, nonzero `RESET_VAL` parameters (`4'd2` and `4'd1`), not the default `4'd0` every other digit uses.** `bcdcounter_ld`'s default `RESET_VAL = 4'd0` is correct for all four of `ss`/`mm`'s digits and would be silently accepted (no compile error) if left as the default for the hour digits too — producing `hh = 8'h00` on reset exactly as in the bullet above, just arrived at through a different mechanism (an unset parameter instead of a hardcoded literal).

- **Priority order: `reset` must stay the single outermost, unconditional check in every digit counter — never nested inside `enable` or `ena`.** The spec says this explicitly ("reset... can occur even when not enabled"), and it's the same priority rule as [Countslow](../101.%20Countslow/README.md): `if (reset) ... else if (enable) ...`, reset first, no exceptions. Both files here get it right, but it's worth re-stating because this is the problem in the chapter where getting it wrong would be hardest to notice — a clock that ignores `reset` while disabled looks completely normal until the one time someone actually needs to reset it mid-count.

- **Treating `pm` as combinational (derived from `hh`) instead of its own register.** `pm` cannot be computed from the current `hh` value alone — `hh == 8'h12` is true both right after 11:59:59→12:00:00 PM *and* right after 11:59:59 AM→12:00:00 PM tomorrow; the bit that's actually "PM or not" is genuinely one bit of state that only changes on a specific edge event, not a function of `hh`. It has to be stored and toggled, exactly as both solutions do — there's no stateless formula for it.

## Solution

See `count_clock.v` (monolithic nested-carry state machine) and `alt1.v` (six instances of a reusable, parameterized, load-capable BCD digit counter).
