onerror {quit -f -code 1}
onbreak {quit -f -code 1}
if {![file exists work]} {vlib work}
vmap work work
vlog -sv ../rtl/reset_release.v ../rtl/ultrasonic_ranger.v ../rtl/distance_display.v ../rtl/active_buzzer.v ../rtl/buzzer_tone_gate.v ../rtl/step_ultrasonic_top.v tb_step_ultrasonic.sv
vsim -voptargs=+acc work.tb_step_ultrasonic
log /tb_step_ultrasonic/clk /tb_step_ultrasonic/key_n /tb_step_ultrasonic/echo /tb_step_ultrasonic/trig /tb_step_ultrasonic/buzzer /tb_step_ultrasonic/seg1 /tb_step_ultrasonic/seg2
log /tb_step_ultrasonic/dut/distance_cm /tb_step_ultrasonic/dut/valid /tb_step_ultrasonic/dut/sample_done
run -all
quit -f -code 0
