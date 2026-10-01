# Verification Plan

## 1. Verification Goal

The goal of verification is to gather evidence that the Tiny Tensor Accelerator computes signed 2x2 matrix multiplication correctly and follows its custom valid/ready transaction rules. Directed simulations alone do not prove correctness for all possible inputs and timings.

The current design under test is:

matrix_accelerator_2x2

## 2. DUT Features Verified

The verification environment currently checks:

- Reset behavior
- Signed MAC accumulation
- 2x2 matrix multiplication correctness
- Positive input values
- Negative input values
- valid_in / ready_in input handshake
- valid_out / ready_out output handshake
- Output backpressure behavior
- Output data stability while ready_out is low
- Rejection of new input while the accelerator is busy

## 3. Directed Tests

| Test | Description |
|------|-------------|
| reset_test | Verify ready_in is high and valid_out is low after reset |
| positive_matrix_test | Verify multiplication of positive 2x2 matrices |
| signed_matrix_test | Verify multiplication with negative signed values |
| backpressure_test | Keep ready_out low and verify valid_out remains high |
| output_stability_test | Verify output data remains stable during backpressure |
| busy_input_reject_test | Try to send new input while busy and verify it is ignored |

## 4. Expected Reference Result

For:

A = [1 2]
    [3 4]

B = [5 6]
    [7 8]

Expected:

C = [19 22]
    [43 50]

## 5. Handshake Rules

### Input Interface

Input is accepted only when:

valid_in == 1 && ready_in == 1

If ready_in is low, input data must not be accepted.

### Output Interface

Output is valid when:

valid_out == 1

If ready_out is low, the accelerator must hold:

- valid_out high
- output data stable
- ready_in low

The accelerator can return to IDLE only after:

valid_out == 1 && ready_out == 1

## 6. Current Limitations

The current verification is based on directed SystemVerilog tests.

Not yet implemented:

- ModelSim confirmation of the new seeded random/reset regression
- A transaction-queue scoreboard for randomized traffic
- Functional coverage
- SystemVerilog assertions
- 4x4 matrix support

## 7. Session 3 Simulation Evidence

The user supplied a ModelSim Intel FPGA Edition 10.5b transcript on October 1, 2026. It shows all eight Python reference vectors matching RTL, followed by `PASS: 8 Python reference vectors matched RTL` and `$finish` at 756 ns. The visible accelerator and vector-testbench compile summaries report zero errors and zero warnings. A normal `$finish` break is the end of the test, not a failure.

Reaching this summary means the procedural checks passed for all eight transactions: five-cycle result latency, signed arithmetic, two cycles of output backpressure, and return to idle after result consumption. This is directed simulation evidence for the default 8/32 configuration; it is not exhaustive verification or a coverage measurement.

## 8. Next Regression Milestone

- Preserve the passing directed regression: run `sim/run_matrix_accelerator_vectors.do` from `sim/` to check all eight Python reference cases. The testbench reads 12 signed decimal fields per line, checks E0-to-E5 latency and the expected result, holds each output for two cycles, and reports the first mismatch with both input matrices.
- Run the new [Session 4 regression](session4_verification.md) for seeds 17, 23, and 42. It includes 8 directed and 100 random pairs per seed, input gaps, always-ready outputs, 1/2/5/20-cycle stalls, a held-pending input pair, and reset after E0/E1/E3/E4/E5 with fresh transactions afterward. These HDL runs are pending.
- Compare transaction accounting: accepted inputs must equal checked outputs plus reset cancellations; consumed outputs must equal checked outputs.
- Retain the failing seed, vector file, source/tool versions, and transcript for reproducibility.
- Check valid/data stability under stalls and record which scenarios were exercised.
- After the AXI4-Stream adapter is specified, test its actual signals and transfer rules at the external ports.

Coverage numbers and AXI compliance must not be claimed until those checks are implemented and run.
