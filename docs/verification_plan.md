# Verification Plan

## 1. Verification Goal

The goal of verification is to prove that the Tiny Tensor Accelerator computes signed 2x2 matrix multiplication correctly and follows the valid/ready handshake protocol.

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
- Python golden model
- Scoreboard-based comparison
- Functional coverage
- SystemVerilog assertions
- 4x4 matrix support