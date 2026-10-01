# Project Scope and Roadmap

## Goal

Design a small, explainable matrix-multiplication IP in SystemVerilog and build evidence for RTL design, verification, integration, and synthesis/timing discussions. This is a design-first project: verification and implementation measurements support microarchitecture decisions.

## Current baseline

- Signed 2x2 multiplication with four parallel MAC units and a compute FSM.
- Default signed 8-bit inputs, signed 32-bit outputs; width parameters are present but alternate configurations have not been qualified.
- Custom valid/ready input/output transaction interface, with output holding under backpressure.
- Directed self-checking tests for arithmetic, reset, signed inputs, stalls, and input attempts while busy.
- Independent Python arithmetic reference and deterministic signed-boundary vectors consumed by RTL simulation; all eight directed vectors passed.
- Seeded arithmetic/stall/reset regression passed for seeds 17/23/42, with pending-input and reset-recovery evidence.
- Session 5 design-tradeoff review and immediate protocol assertions added; checker-enabled simulations are pending.

See [microarchitecture](microarchitecture.md) and [verification plan](verification_plan.md) for details.

## Next milestone

1. Complete the Session 5 tradeoff review and checker self-tests, then preserve the passing regressions with assertions enabled.
2. Synthesize the existing core for a comparable baseline, with clock and I/O constraints recorded.
3. Specify and implement an AXI4-Stream wrapper for 2x2 input/output transactions.
4. Verify the integrated wrapper and core, then synthesize and document resources, timing, and limits.

## Potential later extensions

- One-MAC resource-shared architecture for a measured area/latency comparison.
- Larger matrices or a systolic architecture, after deciding the memory/data-delivery scheme.
- AXI4-Lite control registers if software-visible configuration becomes useful.
- UVM environment if verification-focused roles justify the setup and simulator requirements.

Pipelining, 4x4 support, AXI, UVM, and ASIC physical design are not current capabilities.

## Remaining session schedule

Sessions 1-4 are complete. The 50-hour plan continues in nominal five-hour sessions:

| Session | Work | Primary skills |
| --- | --- | --- |
| 5 | Architecture tradeoffs and reusable protocol checks | FSM/cycle reasoning, signed widths, immediate assertions, fault injection. |
| 6 | FPGA synthesis baseline | Exact target, clock/I/O constraints, resource reports, static timing and unconstrained-path review. |
| 7 | AXI4-Stream adapter specification | Transfer rules, widths/packing, buffering, reset behavior, verification requirements. |
| 8 | Adapter implementation | SystemVerilog integration, valid/ready control, storage ownership. |
| 9 | Integrated verification | Independent reference checking, stalls/reset/ordering, interface assertions and reproducible regression. |
| 10 | Comparable synthesis, final docs and interview preparation | Resource/timing comparison, evidence-backed CV wording, technical explanation. |

Tool setup/debug may need extra time. A physical FPGA board and UVM are not required for this milestone.
