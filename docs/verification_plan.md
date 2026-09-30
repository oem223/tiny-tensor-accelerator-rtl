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

- Randomized testing
- ModelSim confirmation of the new RTL testbench consuming Python reference vectors
- A transaction-queue scoreboard for randomized traffic
- Functional coverage
- SystemVerilog assertions
- 4x4 matrix support

## 7. Next Regression Milestone

- Run `sim/run_matrix_accelerator_vectors.do` from `sim/` to check all eight Python reference cases. The testbench reads 12 signed decimal fields per line, checks E0-to-E5 latency and the expected result, holds each output for two cycles, and reports the first mismatch with both input matrices.
- Generate seeded random matrix pairs after the directed vector regression passes in ModelSim.
- For seeded randomized traffic, compare multiple transactions and keep the failing seed and operands.
- Vary input timing, output stalls, and reset during processing or a pending result.
- Check valid/data stability under stalls and record which scenarios were exercised.
- After the AXI4-Stream adapter is specified, test its actual signals and transfer rules at the external ports.

Coverage numbers and AXI compliance must not be claimed until those checks are implemented and run.
