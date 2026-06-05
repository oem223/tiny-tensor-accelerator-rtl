# Tiny Tensor Accelerator RTL

A SystemVerilog RTL project implementing a small matrix multiplication accelerator using MAC units, control FSMs, signed arithmetic, and valid/ready handshaking.

This project is built as a chip-design-oriented portfolio project, focusing on RTL design, microarchitecture, simulation, verification, and synthesis analysis.

## Project Motivation

Matrix multiplication is a core operation in AI accelerators, GPUs, DSP systems, and many compute architectures.

Each output element is computed using multiply-accumulate operations:

```text
C[i][j] = sum(A[i][k] * B[k][j])