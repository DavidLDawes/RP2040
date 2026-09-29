/*
  mhs_cnc_map.h - board map for the "cnc" role: 8 axes on a Raspberry Pi Pico / Pico 2

  Part of grblHAL (fork addition, DavidLDawes/RP2040)

  grblHAL is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  grblHAL is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with grblHAL. If not, see <http://www.gnu.org/licenses/>.
*/

// Uses every GPIO a Pico / Pico 2 (RP2350A) exposes: 0-22 and 26-28.
//
//   GPIO 2-9    step X Y Z A B C U V      (PIO, must be consecutive)
//   GPIO 10-17  direction X Y Z A B C U V
//   GPIO 18-22  limit / home inputs X Y Z U V
//   GPIO 26     E-stop (reset/halt input)
//   GPIO 27     stepper enable (all drivers)
//   GPIO 28     probe
//   GPIO 0      spindle on/off
//   GPIO 1      coolant flood
//
// One enable output shared by all drivers ($4 sets its polarity, $1/$37 when it releases).
// No limit inputs for A, B and C, no cycle start / feed hold / safety door / mist coolant
// inputs or outputs (cycle start can be sent over the stream, e.g. by mhs2core).
// GPIO 0/1 are the default UART0 pins (Debug Probe console); grblHAL uses USB CDC.
// Designed for 5-axis machines (X Y Z U V) with A B C available; not yet built as
// real hardware, see Controller/PICO2-PLAN.md 2.1.
//
// The role file (roles/cnc.cmake) sets the options core defaults before this file
// is read: N_AXIS=8, SPINDLE0_ENABLE=SPINDLE_ONOFF0, COOLANT_ENABLE=COOLANT_FLOOD and
// CONTROL_ENABLE=CONTROL_HALT. The #errors below catch a mismatch.

#define BOARD_NAME "MHS CNC 8-axis"

#if TRINAMIC_ENABLE
#error Trinamic plugin not supported!
#endif

#if N_AXIS != 8
#error "mhs_cnc_map.h is an 8-axis map, set N_AXIS=8 (roles/cnc.cmake does)"
#endif

#if DRIVER_SPINDLE_ENABLE & (SPINDLE_PWM|SPINDLE_DIR)
#error "mhs_cnc_map.h has a single on/off spindle output: set SPINDLE0_ENABLE=SPINDLE_ONOFF0"
#endif

#if COOLANT_ENABLE & COOLANT_MIST
#error "mhs_cnc_map.h has no mist coolant output: set COOLANT_ENABLE=COOLANT_FLOOD"
#endif

#if CONTROL_ENABLE & ~CONTROL_HALT
#error "mhs_cnc_map.h has an E-stop input only: set CONTROL_ENABLE=CONTROL_HALT"
#endif

// Define step pulse output pins.
#define STEP_PORT               GPIO_PIO  // N_AXIS pin PIO SM
#define STEP_PINS_BASE          2         // N_AXIS number of consecutive pins are used by PIO

// Define step direction output pins.
#define DIRECTION_PORT          GPIO_OUTPUT
#define X_DIRECTION_PIN         10
#define Y_DIRECTION_PIN         11
#define Z_DIRECTION_PIN         12
#define DIRECTION_OUTMODE       GPIO_SHIFT10

// Define stepper driver enable/disable output pin.
#define ENABLE_PORT             GPIO_OUTPUT
#define STEPPERS_ENABLE_PIN     27

// Define homing/hard limit switch input pins.
#define X_LIMIT_PIN             18
#define Y_LIMIT_PIN             19
#define Z_LIMIT_PIN             20
#define LIMIT_INMODE            GPIO_MAP

// A axis (motor 3): step and direction, no limit input.
#define M3_AVAILABLE
#define M3_STEP_PIN             (STEP_PINS_BASE + 3)
#define M3_DIRECTION_PIN        (Z_DIRECTION_PIN + 1)

// B axis (motor 4): step and direction, no limit input.
#define M4_AVAILABLE
#define M4_STEP_PIN             (STEP_PINS_BASE + 4)
#define M4_DIRECTION_PIN        (Z_DIRECTION_PIN + 2)

// C axis (motor 5): step and direction, no limit input.
#define M5_AVAILABLE
#define M5_STEP_PIN             (STEP_PINS_BASE + 5)
#define M5_DIRECTION_PIN        (Z_DIRECTION_PIN + 3)

// U axis (motor 6)
#define M6_AVAILABLE
#define M6_STEP_PIN             (STEP_PINS_BASE + 6)
#define M6_DIRECTION_PIN        (Z_DIRECTION_PIN + 4)
#define M6_LIMIT_PIN            21

// V axis (motor 7)
#define M7_AVAILABLE
#define M7_STEP_PIN             (STEP_PINS_BASE + 7)
#define M7_DIRECTION_PIN        (Z_DIRECTION_PIN + 5)
#define M7_LIMIT_PIN            22

// Auxiliary outputs
#define AUXOUTPUT0_PORT         GPIO_OUTPUT // Spindle on/off
#define AUXOUTPUT0_PIN          0
#define AUXOUTPUT1_PORT         GPIO_OUTPUT // Coolant flood
#define AUXOUTPUT1_PIN          1

// Define driver spindle pins
#if DRIVER_SPINDLE_ENABLE
#define SPINDLE_PORT            GPIO_OUTPUT
#endif
#if DRIVER_SPINDLE_ENABLE & SPINDLE_ENA
#define SPINDLE_ENABLE_PIN      AUXOUTPUT0_PIN
#endif

// Define flood coolant enable output pin.
#if COOLANT_ENABLE
#define COOLANT_PORT            GPIO_OUTPUT
#endif
#if COOLANT_ENABLE & COOLANT_FLOOD
#define COOLANT_FLOOD_PIN       AUXOUTPUT1_PIN
#endif

// Auxiliary inputs
#define AUXINPUT0_PIN           26 // Reset/EStop
#define AUXINPUT1_PIN           28 // Probe

// Define user-control controls (reset/E-stop) input pins.
#if CONTROL_ENABLE & CONTROL_HALT
#define RESET_PIN               AUXINPUT0_PIN
#endif
#if PROBE_ENABLE
#define PROBE_PIN               AUXINPUT1_PIN
#endif
