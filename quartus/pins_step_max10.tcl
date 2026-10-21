# Official STEP MAX10 section 1.6. External GPIO choices are project-specific.
set_location_assignment PIN_J5 -to clk_12m
set_location_assignment PIN_J9 -to key1_n
# User confirmed physical connections: TRIG=GPIO3, ECHO=GPIO4, BEEP IO=GPIO5.
set_location_assignment PIN_R3 -to trig_out
set_location_assignment PIN_L6 -to echo_in
set_location_assignment PIN_P4 -to buzzer_out
set_location_assignment PIN_N15 -to {led_n[0]}
set_location_assignment PIN_N14 -to {led_n[1]}
foreach signal {clk_12m key1_n echo_in trig_out buzzer_out} {
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to $signal
}
foreach {signal pins} {
    seg1 {E1 D2 K2 J2 G2 F5 G5 L1 E2}
    seg2 {A3 A2 P2 P1 N1 C1 C2 R2 B1}
    led_n {N15 N14}
} {
    set bit 0
    foreach pin $pins {
        set node [format {%s[%d]} $signal $bit]
        set_location_assignment PIN_$pin -to $node
        set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to $node
        incr bit
    }
}
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to key1_n
# Segment/LED series resistors are already fitted on the board.
foreach signal {trig_out buzzer_out seg1[*] seg2[*] led_n[*]} {
    set_instance_assignment -name CURRENT_STRENGTH_NEW "4MA" -to $signal
}
# Each common cathode sinks the total current of the illuminated segments.
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to {seg1[8]}
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to {seg2[8]}
