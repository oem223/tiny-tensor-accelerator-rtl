vlib work
vlog -sv ../rtl/mac_unit.sv
vlog -sv ../rtl/matrix_mult_2x2.sv
vlog -sv ../rtl/matrix_accelerator_2x2.sv
vlog -sv ../tb/accelerator_protocol_checker.sv
vlog -sv ../tb/matrix_accelerator_vectors_tb.sv
vsim work.matrix_accelerator_vectors_tb

run -all
