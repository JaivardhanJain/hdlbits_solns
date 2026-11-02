# Always_nolatches

**HDLBits link:** https://hdlbits.01xz.net/wiki/Always_nolatches
**Category:** Verilog Language: Procedures
**Difficulty:** ⭐⭐⭐

## Problem summary

Decode the last two bytes of a PS/2 keyboard scancode into four arrow-key outputs. `16'he06b` sets `left`, `16'he072` sets `down`, `16'he074` sets `right`, `16'he075` sets `up`. Any other scancode leaves all four outputs at 0.

## Approach

This is a `case` with four outputs instead of one, and that's what makes it harder than [Always_case](../33.%20Always_case/README.md). Each item only cares about one output, but a combinational block has to assign **every** output on **every** path, or the ones it skips turn into latches.

The fix is the default-assignment idiom from [Always_if](../31.%20Always_if/README.md): set every output to 0 at the top of the block, then let the matching item override the one output it's responsible for.

```verilog
always @(*) begin
    left = 1'b0; down = 1'b0; right = 1'b0; up = 1'b0;
    case (scancode)
        16'he06b: left  = 1'b1;
        16'he072: down  = 1'b1;
        16'he074: right = 1'b1;
        16'he075: up    = 1'b1;
    endcase
end
```

Every path now assigns all four outputs: either the top line alone (no match), or the top line followed by one override. No `default:` item is needed, because "no match" already leaves the right values in place.

An equally good version skips the `always` block entirely: `assign left = (scancode == 16'he06b);` and so on, one comparator per output. It can't infer a latch at all, but the outputs then have to be declared without `reg`, which doesn't match the header HDLBits gives.

## Gotchas / things I got wrong initially

- **A `default:` item alone doesn't prevent the latch.** The obvious approach is to write each item with its one output and put the zeros in `default:`:

  ```verilog
  case (scancode)
      16'he06b: left = 1'b1;
      16'he072: down = 1'b1;
      ...
      default:  begin left = 0; down = 0; right = 0; up = 0; end
  endcase
  ```

  The `default` only runs when nothing matches. When `scancode` is `16'he06b`, only `left` is assigned, and `down`, `right` and `up` hold whatever they had before. That's a latch on each of them. Trace the scancode changing from down to left:

  | step | `scancode` | `left` | `down` | `right` | `up` |
  |---|---|---|---|---|---|
  | 1 | `16'h0000` | 0 | 0 | 0 | 0 |
  | 2 | `16'he072` | 0 (held) | **1** | 0 (held) | 0 (held) |
  | 3 | `16'he06b` | **1** | 1 (held) | 0 (held) | 0 (held) |

  At step 3 both `left` and `down` are high. To fix it this way, every item would have to assign all four outputs, 4 × 5 = 20 assignments. The defaults at the top do the same thing in one line.

- **This doesn't contradict "always keep a `default`".** [Always_case](../33.%20Always_case/README.md) said to keep a `default` even when every value is covered. The reason was to make sure every path assigns the output, including `x` or `z` inputs in simulation. The top-of-block defaults already guarantee that, for every input including `x`, so a `default:` item would just repeat them. Some lint setups still want one in every `case`. If yours does, `default: ;` (an empty statement) satisfies it without hiding anything.

- **The overrides work because the last assignment wins, not because hardware runs line by line.** It's tempting to read the block as "first set everything to 0, then set one to 1, so there's a brief moment where it's 0". There isn't. Synthesis evaluates the whole block and builds logic for the final value of each output: `left` becomes a single comparator, `scancode == 16'he06b`, with no glitch from the "earlier" 0. The order matters only in deciding which assignment is final, which is why the defaults have to come **before** the `case`. Put them after it and they overwrite the overrides, so all four outputs are always 0.

- **The scancodes are 16 bits, so the item constants have to be too.** `16'he06b` includes the `E0` extended-key prefix. Writing just the code byte, as `8'h6b` or `16'h6b`, zero-extends to `16'h006b`, which never equals `16'he06b`, so the item never matches. No error, just an output stuck at 0. Same sized-literal lesson as Step One: match every constant's width to the signal it's compared against.

## Solution

See `always_nolatches.v`
