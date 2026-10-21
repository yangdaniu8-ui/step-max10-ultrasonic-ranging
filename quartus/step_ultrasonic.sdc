create_clock -name clk_12m -period 83.333 [get_ports {clk_12m}]
derive_clock_uncertainty
# ECHO is asynchronous. Only the path into the first synchronizer is excluded.
set_false_path -from [get_ports {echo_in}] -to [get_registers {*u_ranger|echo_meta}]
# Reset button asynchronously asserts the release pipeline.
set_false_path -from [get_ports {key1_n}]
# Human-facing outputs have no receiving clock; allow a nominal 5 ns budget.
set_output_delay -clock clk_12m -max 5.000 [get_ports {trig_out buzzer_out seg1[*] seg2[*] led_n[*]}]
set_output_delay -clock clk_12m -min 0.000 [get_ports {trig_out buzzer_out seg1[*] seg2[*] led_n[*]}]
