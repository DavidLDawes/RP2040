# Role "cnc": 8-axis CNC control (X Y Z A B C U V), meant mostly for 5-axis
# machines (X Y Z U V), with A B C available.
#
# Pin map: boards/mhs_cnc_map.h (see there and roles/README.md for the pinout).
# It uses every GPIO: step 2-9, direction 10-17, limits X Y Z U V 18-22, E-stop 26,
# stepper enable 27, probe 28, spindle on/off 0, coolant flood 1. No cycle start input.
#
# These options must come from here, not the map: core sets their defaults before
# the board map is read.
#   N_AXIS=8                          the map does not raise N_AXIS itself
#   SPINDLE0_ENABLE=SPINDLE_ONOFF0    one on/off spindle output (no PWM, no direction)
#   COOLANT_ENABLE=COOLANT_FLOOD      flood only (no mist output)
#   CONTROL_ENABLE=CONTROL_HALT       E-stop (reset/halt) input only, no feed hold or
#                                     cycle start (driver.h defaults to all three)

add_compile_definitions(
    BOARD_MHS_CNC
    N_AXIS=8
    SPINDLE0_ENABLE=SPINDLE_ONOFF0
    COOLANT_ENABLE=COOLANT_FLOOD
    CONTROL_ENABLE=CONTROL_HALT
)
