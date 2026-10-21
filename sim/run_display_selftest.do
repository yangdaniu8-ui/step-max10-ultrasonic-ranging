onerror {quit -f -code 1}
onbreak {quit -f -code 1}
if {![file exists work]} {vlib work}
vmap work work
vlog -sv ../rtl/reset_release.v ../rtl/board_display_selftest.v tb_display_selftest.sv
vsim work.tb_display_selftest
run -all
quit -f -code 0
