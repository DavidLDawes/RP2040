# roles/

Fork addition (not upstream). A **role** is what a board does on the bench: `cnc`,
`turntable`, ... Each role is one CMake file of compile-time definitions, injected
into the build with `-DCMAKE_PROJECT_grblHAL_INCLUDE=roles/<role>.cmake`. That is the
same mechanism CI uses, so no build needs `my_machine.h` edited.

One image per **board type × role**. The board type (`PICO_BOARD`) chooses the chip;
the role chooses the machine configuration. Every board keeps its own settings in its
own flash.

## Building

```
scripts\build.ps1 -Board pico2 -Role cnc      # explicit
scripts\build.ps1 -Device cnc-2               # from the bench registry (Controller/bench/boards.json)
```

The script always passes `-DPICO_BOARD`, so it's immune to the reconfigure trap
(Controller/PICO2-PLAN.md 1.3). It builds into `build-<board>-<role>/` and copies the
image to `build-<board>-<role>/grblHAL-<board>-<role>.uf2`. It then checks and prints
the chip, the **axis count** and the **settings address**, and fails on a mismatch.
The toolchain is found in `~/play/toolchain` (or `-Toolchain` / `PICO_TOOLCHAIN_DIR`).

CI builds every role for both `pico` and `pico2` and checks the axis count.

## Roles

| Role | Axes | Pin map | Status |
|---|---|---|---|
| `default` | 3 (X Y Z) | `boards/generic_map.h` | what `my_machine.h` alone builds; the bench Pico has run this so far |
| `cnc` | 8 (X Y Z A B C U V) | `boards/mhs_cnc_map.h` (`BOARD_MHS_CNC`) | builds for both chips; a design on paper, since no such machine exists yet |

### `cnc` pinout

8 axes are built, but the map is laid out for the usual 5-axis case (X Y Z U V), with
A B C available. It uses every GPIO the Pico and Pico 2 expose (0-22, 26-28):

| GPIO | Signal |
|---|---|
| 2-9 | step X Y Z A B C U V (PIO, consecutive) |
| 10-17 | direction X Y Z A B C U V |
| 18, 19, 20, 21, 22 | limit/home X, Y, Z, U, V |
| 26 | E-stop (reset/halt input; `ESTOP_ENABLE` is on) |
| 27 | cycle start |
| 28 | probe (the same pin as the default map) |
| 0 | spindle on/off |
| 1 | coolant flood |

- **No stepper enable output** (there's no pin left), so drivers must be enabled in
  hardware. There are also no limit inputs for A, B and C, no feed hold, no safety door
  and no mist coolant. The spindle is on/off only: no PWM speed and no direction.
- The role file sets the options core defaults *before* the board map is read
  (`N_AXIS=8`, `SPINDLE0_ENABLE=SPINDLE_ONOFF0`, `COOLANT_ENABLE=COOLANT_FLOOD`,
  `CONTROL_ENABLE=(CONTROL_HALT|CONTROL_CYCLE_START)`). The map `#error`s if they don't
  match its pins.
- **Different pins from `default`**: a board wired for `default` must be rewired before
  it's flashed with `cnc`.
- GPIO 0/1 are UART0's default pins (where a Debug Probe's console usually connects).
  grblHAL uses USB, so they're free for the two outputs.
- A real 8-axis machine would need more I/O than this, for example a multiplexer on
  these pins giving 4 banks of 8. That's out of scope for now.

**RP2350 A2 boards** (erratum E9): keep inputs on pull-ups, with `$18` = 0 and switches
wired to ground. See Controller/PICO2-PLAN.md 1.1.
