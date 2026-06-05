vlib work
vlog -sv ../rtl/mac_unit.sv
vlog -sv ../rtl/matrix_mult_2x2.sv
vlog -sv ../tb/matrix_mult_2x2_tb.sv
vsim work.matrix_mult_2x2_tb

add wave -r *

run -all