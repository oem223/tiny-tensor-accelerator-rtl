# Tiny Tensor Accelerator RTL

## Goal

This project implements a small matrix multiplication accelerator in SystemVerilog.

The goal is to practice chip-design-oriented RTL development, including datapath design, MAC units, control FSMs, signed arithmetic, valid/ready handshaking, pipelining, verification, waveform debugging, and synthesis analysis.

## Motivation

Matrix multiplication is a core operation in AI accelerators, GPUs, DSP systems, and many compute architectures.

Each output element is computed using multiply-accumulate operations:

C[i][j] = sum(A[i][k] * B[k][j])

This makes the project a good small-scale example of compute-accelerator design.

## Planned Versions

### Version 1

2x2 signed matrix multiplication using MAC units.

### Version 2

FSM-controlled sequential matrix multiplication accelerator.

### Version 3

Parameterized 4x4 INT8 matrix multiplication accelerator.

### Version 4

Optional systolic-array architecture.

### Version 5

Synthesis reports, timing analysis, and documentation.

## Target Skills

- SystemVerilog RTL
- Digital design
- Microarchitecture
- Datapath/control separation
- MAC units
- Signed arithmetic
- Pipelining
- Verification
- Synthesis analysis