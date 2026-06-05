# Microarchitecture

## Current Design: 2x2 Matrix Multiplier

The current accelerator computes:

C = A × B

for signed 2x2 matrices.

A and B use 8-bit signed inputs.  
C uses 32-bit signed outputs.

## Matrix Equation

For:

A = [a00 a01]
    [a10 a11]

B = [b00 b01]
    [b10 b11]

The output matrix is:

c00 = a00*b00 + a01*b10  
c01 = a00*b01 + a01*b11  
c10 = a10*b00 + a11*b10  
c11 = a10*b01 + a11*b11  

## Datapath

The design uses four MAC units:

- MAC00 computes c00
- MAC01 computes c01
- MAC10 computes c10
- MAC11 computes c11

Each MAC performs:

acc = acc + a*b

## Control FSM

The module uses a finite state machine with the following states:

| State | Description |
|------|-------------|
| S_IDLE | Wait for start |
| S_CLEAR | Clear all MAC accumulators |
| S_COMPUTE_K0 | Compute the first product for each output |
| S_COMPUTE_K1 | Compute the second product for each output |
| S_DONE | Output matrix is valid |

## Cycle Behavior

After start is asserted:

1. Input matrices are captured into internal registers.
2. MAC accumulators are cleared.
3. First multiplication step is executed.
4. Second multiplication step is executed.
5. done is asserted.

## Latency

The current design takes approximately 4 clock cycles from start to done:

- 1 cycle to capture inputs and move to clear
- 1 cycle to clear accumulators
- 1 cycle for K0 computation
- 1 cycle for K1 computation
- done is asserted after computation finishes

## Current Architecture Choice

This version uses four MAC units in parallel.

Advantages:

- Simple control
- Fast for 2x2 matrix multiplication
- Clear mapping between output elements and MAC units

Disadvantages:

- Uses more hardware than a single-MAC design
- Not yet parameterized for larger matrices