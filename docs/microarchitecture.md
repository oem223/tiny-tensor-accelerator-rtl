# Microarchitecture

## 1. Current Design: 2x2 Matrix Multiplier

The current accelerator computes:

C = A × B

for signed 2x2 matrices.

The input matrices A and B use 8-bit signed values.  
The output matrix C uses 32-bit signed values.

## 2. Matrix Equation

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

## 3. MAC Unit

The basic compute block is the MAC unit.

A MAC unit performs:

acc = acc + a*b

The current design uses a signed MAC with:

- 8-bit signed inputs
- 32-bit signed accumulator
- clear control
- enable control
- asynchronous active-low reset

## 4. Datapath

The 2x2 matrix multiplier uses four MAC units in parallel:

| MAC Unit | Output Computed |
|---------|-----------------|
| MAC00 | c00 |
| MAC01 | c01 |
| MAC10 | c10 |
| MAC11 | c11 |

Each MAC accumulates two products.

## 5. Control FSM

The design uses a finite state machine with the following states:

| State | Description |
|------|-------------|
| S_IDLE | Wait for start |
| S_CLEAR | Clear all MAC accumulators |
| S_COMPUTE_K0 | Compute the first product for each output element |
| S_COMPUTE_K1 | Compute the second product for each output element |
| S_DONE | Output matrix is ready |

## 6. Cycle-Level Operation

After `start` is asserted:

1. Input matrices are captured into internal registers.
2. The MAC accumulators are cleared.
3. The first multiplication step is executed.
4. The second multiplication step is executed.
5. `done` is asserted.

## 7. K0 Computation

During `S_COMPUTE_K0`:

c00 accumulates a00*b00  
c01 accumulates a00*b01  
c10 accumulates a10*b00  
c11 accumulates a10*b01  

## 8. K1 Computation

During `S_COMPUTE_K1`:

c00 accumulates a01*b10  
c01 accumulates a01*b11  
c10 accumulates a11*b10  
c11 accumulates a11*b11  

## 9. Latency

The current design takes approximately 4 cycles from `start` to `done`:

| Cycle | Operation |
|------:|-----------|
| 0 | Capture inputs |
| 1 | Clear MACs |
| 2 | Compute K0 |
| 3 | Compute K1 |
| 4 | Done asserted |

## 10. Architecture Choice

This version uses four MAC units in parallel.

### Advantages

- Simple datapath
- Simple control logic
- Fast for 2x2 matrix multiplication
- Clear mapping between MAC units and output elements

### Disadvantages

- Uses more hardware than a single-MAC sequential design
- Not yet scalable to larger matrices
- The current top-level interface uses custom valid/ready signals; it is not AXI4-Stream yet
- No pipelining yet

## 11. Next Planned Improvements

The next design milestones are:

1. Specify exact accepted-input-to-valid-output timing and width assumptions.
2. Add a Python reference model and seeded randomized regression.
3. Add assertions/checks for transaction and backpressure rules.
4. Obtain a Quartus synthesis and timing baseline for the existing core.
5. Design and verify an AXI4-Stream adapter around the current accelerator.
6. Compare baseline and integrated resource/timing reports under the same target and constraints.

The separate `matrix_accelerator_2x2` module already implements the custom valid/ready interface and stores outputs until accepted. The state table above describes the inner `matrix_mult_2x2` core; the outer transaction controller adds input capture, core-start, and output-holding cycles. The approximate four-cycle figure above refers to the core, not the full top-level interface. Exact top-level latency should be established with a cycle-counted regression before publishing a performance number.