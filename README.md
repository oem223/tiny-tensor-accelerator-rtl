# Matrix Multiplication Accelerator

A small SystemVerilog accelerator for signed 2x2 matrix multiplication. The current design uses four parallel multiply-accumulate (MAC) units, a control FSM, and a custom valid/ready transaction interface.

**Current status:** The RTL and directed self-checking testbenches are committed. A Python reference model, randomized regression, assertions, AXI4-Stream wrapper, and synthesis/timing reports are planned work; they are not implemented yet.

## Computation and architecture

For signed matrices `A` and `B`, each result is `C[i][j] = A[i][0]*B[0][j] + A[i][1]*B[1][j]`. The default configuration uses signed 8-bit matrix elements and signed 32-bit outputs. The core has one MAC per output element and computes the two products across two compute cycles.

| Module | Responsibility |
| --- | --- |
| `rtl/mac_unit.sv` | Signed multiplication and accumulation with clear/enable. |
| `rtl/matrix_mult_2x2.sv` | Four MACs, input capture, and compute FSM. |
| `rtl/matrix_accelerator_2x2.sv` | Input/output transaction control and result holding. |

The accelerator accepts inputs on a rising edge with `valid_in && ready_in`. While processing or holding an output, `ready_in` is low. It presents a result with `valid_out`; if `ready_out` is low, `valid_out` and the result remain stable until a rising edge with `valid_out && ready_out`. These ports implement a project-specific ready/valid interface, **not AXI**.

See the [interface contract draft](docs/interface_contract.md) for transaction and clock behaviour, [microarchitecture](docs/microarchitecture.md) for the existing FSM, and [verification plan](docs/verification_plan.md) for what is checked today and what remains to be built.

## Run the current directed tests

The `.do` scripts use ModelSim/Questa. From the `sim` directory, run:
```text
vsim -do run_mac_unit.do
vsim -do run_matrix_mult_2x2.do
vsim -do run_matrix_accelerator_2x2.do
```

Run each command in a fresh simulator invocation. The scripts compile the RTL and testbench, start simulation, and print PASS/FAIL results. A physical FPGA board is not required.

## Next milestone

1. Specify signed arithmetic, transaction timing, and a reproducible verification matrix.
2. Add a Python reference model and seeded randomized self-checking regression.
3. Add protocol assertions/checks and synthesize the current core for a baseline.
4. Specify, implement, and verify an AXI4-Stream adapter around the existing core.
5. Synthesize the integrated design and document actual resource/timing results.

The planned AXI interface is a separate adapter. Its widths, packing, optional signals, and protocol behaviour will be specified and tested before calling it AXI4-Stream compliant. A 4x4 version, systolic array, AXI4-Lite control registers, and UVM environment are outside this milestone.

This is a design and verification portfolio project. Simulation and FPGA-targeted synthesis reports should be identified as such; they do not demonstrate on-board operation or ASIC sign-off.
