# Run in a fresh ModelSim simulation from sim/.
# Default is a legal trace. Optional: set CHECKER_FAULT 1 (or 2/3).
# Negative tests must stop with the documented CHECKER assertion failure.
vlib work
vlog -sv ../tb/accelerator_protocol_checker.sv
vlog -sv ../tb/accelerator_protocol_checker_tb.sv
if {![info exists CHECKER_FAULT]} {
    set CHECKER_FAULT 0
}
vsim work.accelerator_protocol_checker_tb +FAULT=$CHECKER_FAULT
run -all
