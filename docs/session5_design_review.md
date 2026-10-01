# Session 5: design review and protocol assertions

## Where this fits in chip design

We are refining the microarchitecture and verifying RTL against its interface contract. Sessions 1-4 established functional simulation evidence: signed arithmetic, five-period latency, stalls, pending inputs, and reset cancellation/recovery. Session 5 makes architecture decisions explicit and adds reusable checks. Synthesis and static timing analysis come in Session 6; physical implementation/sign-off are not completed by simulation.

## What the new checker does

`tb/accelerator_protocol_checker.sv` is a verification-only module attached to the Session 3 and Session 4 testbenches. It packs the input/output elements into buses to compare their bits; it does not replace the independent Python arithmetic oracle.

| Requirement | Check / responsibility |
| --- | --- |
| Controls are known outside reset | Reject X/Z on valid, ready, or busy. |
| A waiting input stays offered through acceptance | Source must hold `valid_in` and all input data after a stalled edge. |
| A waiting output stays offered through consumption | DUT must hold `valid_out` and all output data after a stalled edge. |
| Valid payloads contain known bits | Detect uninitialized/X/Z data when meaningful. |
| Exactly one transaction outstanding | Accepted input makes the DUT busy and not ready until output consumption or reset. |
| Result appears at the specified time and persists | No early output; result must be present at the expected sampled edge and every later edge until consumed. |
| No unsolicited or duplicate output | With no accepted transaction pending, the interface must be idle. |
| Reset cancels protocol history | Clear the pending transaction and stall obligations on asynchronous reset assertion. The existing regression checks actual reset outputs/recovery. |

These are **immediate SystemVerilog assertions inside a clocked procedural monitor**, not concurrent temporal SVA properties and not formal proof. They do not require a UVM library. Compile/runtime compatibility still needs confirmation in the user's ModelSim Intel FPGA Edition 10.5b installation.

### Sampling matters

RTL registers use nonblocking assignments: they sample their old inputs at a rising edge and update afterward. The checker samples pre-update values at that edge. Thus a transaction accepted at E0 causes `valid_out` to rise after E5, and the checker first samples that high value at E6. The existing testbench also checks the post-update value at E5 using `#1`. There is no extra latency in the hardware.

The checker validates clock-edge observations. It does not detect every between-edge glitch, prove deadlock freedom, or measure coverage. Its fixed-latency and one-outstanding rules belong to this architecture; future buffering/AXI changes require a revised checker. Reset-time output clearing is checked separately by the existing regression.

### Source contract versus robustness tests

The original `matrix_accelerator_2x2_tb.sv` deliberately withdraws a busy-time input before it can transfer, to test that the DUT ignores unaccepted input. That stimulus does not obey the stronger well-behaved-source hold rule. This new checker is therefore attached only to the Session 3/4 drivers, which hold pending transactions correctly. A checker failure on input stability identifies a source/driver error; output stability identifies a DUT error.

## Run in ModelSim

Use a fresh simulation for each run, with the Transcript working directory set to this branch's `sim/` folder. Run the legal self-test first:

```tcl
set CHECKER_FAULT 0
do run_protocol_checker.do
```

Expected: `PASS: protocol checker legal trace, stalls, pending input, and reset cancellation`.

Then run each negative test separately, restarting/unloading the previous simulation first:

```tcl
set CHECKER_FAULT 1
do run_protocol_checker.do
```

| `CHECKER_FAULT` | Intentional violation | Expected fatal diagnostic |
| --- | --- | --- |
| 1 | Corrupt held output data | `CHECKER: output changed or VALID dropped after stall` |
| 2 | Withdraw a stalled input | `CHECKER: input changed or VALID dropped after stall` |
| 3 | Present output one period early | `CHECKER: output too early, sampled age=5` |

A fatal assertion is the desired result only in these deliberate-fault runs. A negative test that reaches `FAIL: injected fault ... escaped the checker` means the checker missed the violation.

Finally run the actual DUT tests with the checker enabled:

```tcl
do run_matrix_accelerator_vectors.do
```

```tcl
set VECTOR_FILE ../vectors/regression_2x2.txt
do run_matrix_accelerator_regression.do
```

Repeat the regression in fresh simulations using `../vectors/regression_seed23.txt` and `../vectors/regression_seed42.txt`. Generate those local ignored files from the repository root if needed:

```bash
python3 -m model.generate_regression --seed 23 --output vectors/regression_seed23.txt
python3 -m model.generate_regression --seed 42 --output vectors/regression_seed42.txt
```

The vector test should still check eight results. Each seeded run should still report accepted=120, consumed=115, checked=115, cancelled=5, without CHECKER failures. These expected results describe acceptance criteria, not completed Session 5 evidence.

## Evidence and completion gate

The Session 3/4 passes are historical evidence before the new checker. Session 5 is complete after the legal self-test passes, all three deliberate violations are detected, the actual DUT regressions pass with assertions enabled, and the tradeoffs can be explained. Record the simulator version, seed, transcript summaries, and observed diagnostics here. No HDL simulator is installed in the editing workspace, so the new SystemVerilog has not yet been compiled or simulated there.

On October 1, 2026, local `python3 -m unittest model.test_reference model.test_regression` passed all seven Python tests. This validates the unchanged vector-generation/reference code; it does not validate the new HDL checker.

## Knowledge and interview practice

Know what a rising-edge transfer means; how nonblocking assignments affect sampling; how a stall differs from waiting for computation; and how signed product/sum widths grow. An assertion expresses a requirement, a driver produces stimulus, a monitor observes it, and an arithmetic reference predicts the result. UVM organizes these verification roles but is not the definition of verification.

Be ready to explain why valid/data remain stable through the eventual transfer edge, why reset aborts an outstanding transaction, how the checker avoids an E5/E6 off-by-one error, and why deliberately injecting a fault is useful. Say which requirements were tested and which measurements remain pending. Session 6 then gives the architectural reasoning a measured FPGA synthesis/timing baseline.