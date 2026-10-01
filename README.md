# Matrix Multiplication Accelerator

A small SystemVerilog accelerator for signed 2x2 matrix multiplication. The current design uses four parallel multiply-accumulate (MAC) units, a control FSM, and a custom valid/ready transaction interface.

**Current status:** The RTL, directed self-checking testbenches, Python arithmetic reference, and fixed boundary vectors are committed. The Session 3 file-driven regression passed all eight vectors in ModelSim Intel FPGA Edition 10.5b on October 1, 2026 at 756 ns. Session 4 adds seeded vectors, variable stalls, pending-input tests, and reset cancellation/recovery checks; seeds 17, 23, and 42 passed in ModelSim, and the reset/recovery waveform was reviewed. Session 5 adds a design-tradeoff review and reusable immediate protocol assertions with deliberate-fault tests; these new HDL changes await ModelSim validation. AXI4-Stream and synthesis/timing reports remain planned work.

## Computation and architecture

For signed matrices `A` and `B`, each result is `C[i][j] = A[i][0]*B[0][j] + A[i][1]*B[1][j]`. The default configuration uses signed 8-bit matrix elements and signed 32-bit outputs. The core has one MAC per output element and computes the two products across two compute cycles.

| Module | Responsibility |
| --- | --- |
| `rtl/mac_unit.sv` | Signed multiplication and accumulation with clear/enable. |
| `rtl/matrix_mult_2x2.sv` | Four MACs, input capture, and compute FSM. |
| `rtl/matrix_accelerator_2x2.sv` | Input/output transaction control and result holding. |

The accelerator accepts inputs on a rising edge with `valid_in && ready_in`. While processing or holding an output, `ready_in` is low. It presents a result with `valid_out`; if `ready_out` is low, `valid_out` and the result remain stable until a rising edge with `valid_out && ready_out`. These ports implement a project-specific ready/valid interface, **not AXI**.

See the [interface contract](docs/interface_contract.md) for transaction and clock behaviour, [microarchitecture](docs/microarchitecture.md) for the existing FSM, and [verification plan](docs/verification_plan.md) for what is checked today and what remains to be built.

The independent [Python reference model](docs/reference_model.md) generates the deterministic arithmetic vectors used by the RTL regressions. See the [design tradeoffs](docs/design_tradeoffs.md) for exact latency, initiation interval, signed width reasoning, and alternative architectures.

## Run the current directed tests

The `.do` scripts use ModelSim/Questa. From the `sim` directory, run:
```text
vsim -do run_mac_unit.do
vsim -do run_matrix_mult_2x2.do
vsim -do run_matrix_accelerator_2x2.do
vsim -do run_matrix_accelerator_vectors.do
```

Run each command in a fresh simulator invocation. The scripts compile the RTL and testbench, start simulation, and print PASS/FAIL results. A physical FPGA board is not required.

The last script runs from `sim/` and reads `../vectors/directed_2x2.txt`. The verified Session 3 run printed eight individual `PASS: vector` messages and `PASS: 8 Python reference vectors matched RTL` at 756 ns. In the Windows ModelSim GUI, change the Transcript working directory to this repository's `sim/` folder and enter `do run_matrix_accelerator_vectors.do`.

## Next milestone

1. Complete [Session 5](docs/session5_design_review.md): review architecture tradeoffs and run the protocol checker, deliberate-fault tests, and checker-enabled regressions.
2. Preserve the passing [Session 4 seeded/reset regression](docs/session4_verification.md) while making subsequent changes.
3. Produce a synthesis baseline with an exact FPGA target, clock/IO constraints, resource counts, and post-fit timing results.
4. Specify, implement, and verify an AXI4-Stream adapter around the existing core.
5. Synthesize the integrated design and document actual resource/timing results.

The planned AXI interface is a separate adapter. Its widths, packing, optional signals, and protocol behaviour will be specified and tested before calling it AXI4-Stream compliant. A 4x4 version, systolic array, AXI4-Lite control registers, and UVM environment are outside this milestone.

This is a design and verification portfolio project. Simulation and FPGA-targeted synthesis reports should be identified as such; they do not demonstrate on-board operation or ASIC sign-off.
