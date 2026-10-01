# Python Reference Model and Directed Vectors

`model/reference.py` computes the mathematical 2x2 signed matrix product with Python integers. It does not reproduce the RTL's FSM or MAC scheduling, so a control bug in the RTL cannot be hidden by copying its implementation into the expected-result calculation.

Each matrix is passed in row-major order: `(a00, a01, a10, a11)` and `(b00, b01, b10, b11)`. The model returns `(c00, c01, c10, c11)`.

The default input range is `[-128, 127]`, with 32-bit signed results. `-128 * -128 + -128 * -128 = 32768`, so 16 signed result bits would not hold every possible sum; a general exact two-product result needs at least `2*IN_WIDTH+1` signed bits. The model rejects input values and width combinations outside this defined exact-arithmetic contract. The RTL does not yet enforce the width constraint.

From the repository root:

```sh
python3 -m unittest model.test_reference
python3 -m model.generate_vectors
```

The second command checks `vectors/directed_2x2.txt` and rewrites it if its contents differ. Each line contains **12 whitespace-separated decimal integers**:

```text
a00 a01 a10 a11 b00 b01 b10 b11 c00 c01 c10 c11
```

There are no headings or comments in the vector file so `matrix_accelerator_vectors_tb.sv` can parse each line with `$fscanf`. From `sim/`, run `vsim -do run_matrix_accelerator_vectors.do` to test the default 8-bit/32-bit RTL with these eight cases. The user ran this regression in ModelSim Intel FPGA Edition 10.5b on October 1, 2026; all eight vectors matched RTL, with simulation finishing at 756 ns.

Session 4 uses a separate generator, `python3 -m model.generate_regression`, and a separate header/14-field format containing timing controls. See [Session 4 verification](session4_verification.md). Do not feed its file to the Session 3 12-field reader.