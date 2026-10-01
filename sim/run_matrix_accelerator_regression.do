# Run from the repository's sim/ directory in the ModelSim Transcript.
# Optional override: set VECTOR_FILE ../vectors/regression_seed23.txt
vlib work
vlog -sv ../rtl/mac_unit.sv
vlog -sv ../tb/accelerator_protocol_checker.sv
vlog -sv ../rtl/matrix_accelerator_2x2.sv
vlog -sv ../rtl/matrix_mult_2x2.sv
vlog -sv ../tb/matrix_accelerator_regression_tb.sv
if {![info exists VECTOR_FILE]} {
    set VECTOR_FILE ../vectors/regression_2x2.txt
}
vsim work.matrix_accelerator_regression_tb +VECTORS=$VECTOR_FILE
add wave -r *
run -all
