# Project Scope and Roadmap

## Goal

Design a small, explainable matrix-multiplication IP in SystemVerilog and build evidence for RTL design, verification, integration, and synthesis/timing discussions. This is a design-first project: verification and implementation measurements support microarchitecture decisions.

## Current baseline

- Signed 2x2 multiplication with four parallel MAC units and a compute FSM.
- Default signed 8-bit inputs, signed 32-bit outputs; width parameters are present but alternate configurations have not been qualified.
- Custom valid/ready input/output transaction interface, with output holding under backpressure.
- Directed self-checking tests for arithmetic, reset, signed inputs, stalls, and input attempts while busy.
- Independent Python arithmetic reference and deterministic signed-boundary vectors; not yet consumed by RTL simulation.

See [microarchitecture](microarchitecture.md) and [verification plan](verification_plan.md) for details.

## Next milestone

1. Connect the fixed reference vectors to an automated RTL regression, then add seeded random cases and stalls.
2. Check latency and reset during a transaction automatically.
3. Add focused protocol assertions/checks and a verification matrix.
4. Synthesize the existing core for a comparable baseline, with clock and I/O constraints recorded.
5. Specify and implement an AXI4-Stream wrapper for 2x2 input/output transactions.
6. Verify the integrated wrapper and core, then synthesize and document resources, timing, and limits.

## Potential later extensions

- One-MAC resource-shared architecture for a measured area/latency comparison.
- Larger matrices or a systolic architecture, after deciding the memory/data-delivery scheme.
- AXI4-Lite control registers if software-visible configuration becomes useful.
- UVM environment if verification-focused roles justify the setup and simulator requirements.

Pipelining, 4x4 support, AXI, UVM, and ASIC physical design are not current capabilities.
