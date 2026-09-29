# Role "cnc": 8-axis CNC control (X Y Z A B C U V).
#
# Uses boards/generic_map_8axis.h. N_AXIS must be set as well: the map enables up to
# 8 axes but does not raise N_AXIS itself, so BOARD_GENERIC_8AXIS alone still builds
# 3 axes.
#
# CAUTION - read before flashing a board that is wired to a machine:
# * The map's own header says it "is an example for how to enable up to 8 axes, it is
#   not intended for use in a machine".
# * Its pins differ from the default (3-axis) map: step 2-9 (X..V), direction 10-17,
#   stepper enable 18, limit inputs 19-22 (X, Y, Z, A only), spindle PWM/dir/enable
#   26/27/28. A board wired for roles/default.cmake must be rewired first.
# * No probe (PROBE_ENABLE 0), no control inputs such as reset/feed hold/cycle start
#   (CONTROL_ENABLE 0), and no limit inputs for B, C, U, V.
# * Some pins are assigned twice: 21 (Z limit, aux input 1), 22 (A limit, aux input 3 /
#   probe), 28 (spindle enable output, aux input 2), and the spindle enable pin is the
#   same pin as spindle PWM.
# See Controller/PICO2-PLAN.md 2.1 for the plan to replace it with a map of our own.

add_compile_definitions(BOARD_GENERIC_8AXIS N_AXIS=8)
