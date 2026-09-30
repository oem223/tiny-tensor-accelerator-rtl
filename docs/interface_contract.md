# Current 2x2 Accelerator Interface Contract

This document describes the existing `matrix_accelerator_2x2` RTL, before the planned AXI4-Stream adapter. The cycle count below follows the sequential logic and was manually checked against a ModelSim/Questa waveform on September 30, 2026. The Session 3 vector testbench now checks the exact five-cycle latency procedurally; all eight transactions passed in the user-supplied ModelSim transcript on October 1, 2026.

## Data and arithmetic

- `a00`–`a11` and `b00`–`b11` are signed `IN_WIDTH`-bit elements; the default is 8 bits.
- `c00`–`c11` are signed `ACC_WIDTH`-bit results; the default is 32 bits.
- `c[i][j] = a[i][0]*b[0][j] + a[i][1]*b[1][j]`.
- The current MAC sign-extends a `2*IN_WIDTH`-bit product. Its replication expression requires `ACC_WIDTH >= 2*IN_WIDTH` to elaborate. To represent the sum of two signed products without overflow for *all* input values, use `ACC_WIDTH >= 2*IN_WIDTH+1`. These parameter limits are not enforced in RTL yet; only the default 8/32 configuration has directed tests.

## Input transaction

- `ready_in` is high only when the outer controller is in `A_IDLE`.
- At a rising edge with `valid_in && ready_in`, the outer controller captures all eight input elements and becomes busy.
- Changes to input pins while `ready_in` is low do not change the accepted transaction.
- The module does not queue another transaction while busy or while holding an output.

## Output transaction

- `valid_out` is high only when the outer controller is in `A_OUT`.
- `c00`–`c11` are meaningful for the current transaction while `valid_out` is high.
- With `valid_out && !ready_out`, the result registers and `valid_out` remain stable.
- At a rising edge with `valid_out && ready_out`, the transaction is consumed and the controller becomes idle. It cannot accept a new input on that same edge, because `ready_in` is low before the edge.
- `busy` is high in both `A_BUSY` and `A_OUT` (including an output stall).

## Clock sequence

Assume a rising edge `E0` accepts an input transaction and no reset occurs:

| Edge | Outer controller | Inner core and MACs |
| --- | --- | --- |
| E0 | Captures A and B; sets registered `core_start`; enters `A_BUSY`. | Still idle; sees the old value of `core_start`. |
| E1 | Clears `core_start`. | Captures the outer input registers; enters `S_CLEAR`. |
| E2 | Waits. | Clears the four accumulators; enters `S_COMPUTE_K0`. |
| E3 | Waits. | Accumulates the `k=0` products; enters `S_COMPUTE_K1`. |
| E4 | Waits. | Accumulates the `k=1` products; enters `S_DONE`. `core_done` becomes high after this edge. |
| E5 | Captures all four completed results; enters `A_OUT`. | Leaves `S_DONE`. `valid_out` becomes high after this edge. |

The input-acceptance-to-`valid_out` latency is **five clock periods** from E0 to E5 in the inspected waveform. This excludes any time spent waiting for the receiver to assert `ready_out`. The waveform also shows the result-valid state persisting during output backpressure.

## Reset and scope

- `rst_n` is active low and asynchronous in the existing sequential blocks. Assertion clears state and registers; `valid_out` becomes low and `ready_in` becomes high.
- Deassertion near a clock edge, reset recovery/removal timing, and alternate parameter combinations have not been qualified.
- The interface is a custom ready/valid protocol. It is **not** AXI4-Stream; AXI signal choices and data packing belong to a separate future wrapper specification.

## Session 1 evidence and remaining checks

- The user ran all three existing `.do` tests and reported that they passed. The supplied accelerator transcript shows the robust handshake test passing at 266 ns, including three cycles of output backpressure with stable result data.
- The supplied waveform shows input acceptance, `core_start`, `core_done`, and `valid_out` in the E0–E5 order above. The five-cycle latency was checked visually, not by an automated latency assertion.
- Session 3 adds automated E0-to-E5 latency checks for eight vector transactions. The user-supplied ModelSim Intel FPGA Edition 10.5b transcript reports all vectors passed at 756 ns and zero errors/warnings in the visible accelerator and vector-testbench compile summaries.
- Still to check: reset during an in-flight computation or pending output, alternate parameters, randomized traffic, and broader protocol coverage.