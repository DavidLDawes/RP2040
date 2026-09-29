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
| `cnc` | 8 (X Y Z A B C U V) | `boards/generic_map_8axis.h` | **builds for both chips; not for a wired machine yet** (see below) |

### `cnc` caveats

`generic_map_8axis.h` is upstream's *example* map: "an example for how to enable up to
8 axes, it is not intended for use in a machine".

- **Different pins from `default`.** Step 2-9 (X..V), direction 10-17, stepper enable
  18, limit inputs 19-22, spindle PWM/dir/enable 26/27/28. A board wired for `default`
  must be rewired before it's flashed with `cnc`.
- **Missing signals:** no probe, no control inputs (reset, feed hold, cycle start), and
  limit inputs for X, Y, Z and A only.
- **Pins assigned twice:** 21 (Z limit and aux input 1), 22 (A limit and aux input
  3/probe), 28 (spindle enable output and aux input 2). The spindle enable is the same
  pin as spindle PWM.

The Pico has 26 usable GPIOs, and 8 step plus 8 direction pins use 16 of them. So a
real 8-axis map is a pin-budget decision (which axes get limit switches, whether there
is a probe and hardware control inputs). It's planned as a map of our own, in
Controller/PICO2-PLAN.md 2.1.

**RP2350 A2 boards** (erratum E9): keep inputs on pull-ups, with `$18` = 0 and switches
wired to ground. See Controller/PICO2-PLAN.md 1.1.
