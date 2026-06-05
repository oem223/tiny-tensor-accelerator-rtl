vlib work
vlog -sv ../rtl/mac_unit.sv
vlog -sv ../tb/mac_unit_tb.sv
vsim work.mac_unit_tb

add wave -r *

run -all