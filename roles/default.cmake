# Role "default": the build exactly as my_machine.h configures it, with no extra
# definitions. On the generic map that is 3 axes (X, Y, Z), with the pin
# assignments in boards/generic_map.h. The bench Pico has run this so far.
#
# Used by scripts/build.ps1 via -DCMAKE_PROJECT_grblHAL_INCLUDE; see roles/README.md.
