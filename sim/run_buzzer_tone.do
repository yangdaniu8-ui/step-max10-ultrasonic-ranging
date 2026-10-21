onerror {quit -f -code 1}
onbreak {quit -f -code 1}
if {![file exists work]} {vlib work}
vmap work work
vlog -sv ../rtl/buzzer_tone_gate.v tb_buzzer_tone.sv
vsim work.tb_buzzer_tone
run -all
quit -f -code 0
