# Session 4: Seeded Arithmetic, Stalls, and Reset

## Position in the design flow

This is functional verification of the existing accelerator IP, before AXI integration and the synthesis baseline. Session 3 matched eight directed Python vectors against RTL. Session 4 broadens the operands and transaction timing without changing the datapath or controller.

A **stall** is a cycle in which an operation or transfer cannot advance. An output stall occurs at a rising edge with `valid_out && !ready_out`: a result exists, but the receiver cannot consume it. Backpressure is the receiver's request to wait, communicated by deasserting ready. The producer must retain valid and the same data until a transfer or reset.

An **input gap** has `valid_in=0`: the sender has no transaction to offer. This is different from an input waiting with `valid_in=1` and `ready_in=0`. In the latter case, the sender holds valid and its eight elements until acceptance. Computation cycles with no valid output are also not output backpressure.

## Added scenarios and checks

| Scenario | Stimulus | Required behavior |
| --- | --- | --- |
| Arithmetic | 8 directed plus 100 seeded random matrix pairs | Four signed results match the independent Python model; result valid at E5 |
| Input gaps | 0-3 extra idle rising edges before launching | No output or activity appears during the gap |
| Always-ready receiver | Ready high before input acceptance | Result becomes valid at E5 and is consumed at the next rising edge |
| Output stalls | 1, 2, 5, or 20 stalled rising edges | Valid and result remain stable; input ready stays low; busy stays high |
| Pending second input | Hold a second matrix pair valid during the first computation and output stall | First result is retained; second input accepted on the first edge after output release; two results stay ordered |
| Reset after E0/E1/E3/E4 | Assert reset while an accepted transaction is unfinished | Cancel the transaction, clear visible state/data, and emit no stale result |
| Reset after E5 | Reset while holding an unconsumed output | Discard that pending output |
| Restart after each reset | Send a fresh positive matrix pair | Produce the correct fresh result |

Reset is asserted between rising edges and released at a falling edge in these functional tests. This does not qualify physical reset recovery/removal timing or synchronization of reset release.

The testbench counts real input and output handshakes at rising edges before the DUT's nonblocking assignments update its state. It checks outputs after a short simulation delay. With the default 108 file rows, the final accounting must be:

```text
accepted=120 consumed=115 checked=115 cancelled=5
```

The extra checked results are two pending-pair transactions and five fresh transactions after reset. Five other accepted transactions are deliberately cancelled. Scenario counts are diagnostic exercise counts, not functional-coverage percentages. This remains a simple sequential expected-result checker for a single-outstanding design, not a general transaction-queue scoreboard or UVM environment.

## Reproducibility and file format

`model/generate_regression.py` uses a local Python `Random(seed)` instance. A seed recreates operands and timing under the same generator/Python version. Retain the actual vector file, source revision, and tool versions for exact reproduction across environments. The header records the seed and row count:

```text
seed 17 cases 108
```

Each subsequent row contains 14 decimal fields:

```text
a00 a01 a10 a11 b00 b01 b10 b11 c00 c01 c10 c11 input_gap_cycles output_stall_cycles
```

The existing 12-field Session 3 vector file and runner remain usable. The committed Session 4 file is seed 17. Generate seeds 23 and 42 into separate ignored files for additional runs.

## Run in Windows

From the repository root in Git Bash:

```sh
python3 -m unittest model.test_reference model.test_regression
python3 -m model.generate_regression
python3 -m model.generate_regression --seed 23 --output vectors/regression_seed23.txt
python3 -m model.generate_regression --seed 42 --output vectors/regression_seed42.txt
```

In the Windows ModelSim Transcript, change to the repository's `sim/` directory and run:

```tcl
quit -sim
set VECTOR_FILE ../vectors/regression_2x2.txt
do run_matrix_accelerator_regression.do
```

If no simulation is loaded, omit `quit -sim`. Repeat for the other files:

```tcl
quit -sim
set VECTOR_FILE ../vectors/regression_seed23.txt
do run_matrix_accelerator_regression.do
quit -sim
set VECTOR_FILE ../vectors/regression_seed42.txt
do run_matrix_accelerator_regression.do
```

Each successful run reports timing-scenario counts, transaction accounting, and:

```text
PASS: Session 4 seed=17 vectors=108 pending_pair=1 reset_scenarios=5
```

The seed changes for the other runs. A failure stops the run with a seed, case, or named scenario. An arithmetic mismatch prints both matrices and expected/actual results. Save that transcript before changing the stimulus.

## Evidence and completion gate

Local Python checks pass: seven unit tests and generation of seeds 17, 23, and 42. The HDL simulator is unavailable in the agent workspace. The user-supplied ModelSim transcript on October 1, 2026 shows seed 17 passing at 16,406 ns: 108 vectors, the pending-input pair, and five reset/recovery scenarios. The visible regression-testbench compile summary reports zero errors and zero warnings. Accounting is accepted=120, consumed=115, checked=115, cancelled=5. Scenario counts are always_ready=32, short_stall=53, long_stall=23, input_gap=80, stalled_edges=610, resets=5. The user supplied passing transcripts for seeds 23 and 42 as well. All three runs report accepted=120, consumed=115, checked=115, cancelled=5, with the pending-input pair and all five reset scenarios passing. Full compile-warnings review and visual inspection of a reset waveform remain pending.

| Seed | Result | Finish time (ns) | Always ready | Short stall | Long stall | Input gaps | Stalled edges |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 17 | PASS | 16406 | 32 | 53 | 23 | 80 | 610 |
| 23 | PASS | 15146 | 27 | 65 | 16 | 81 | 484 |
| 42 | PASS | 15416 | 24 | 69 | 15 | 81 | 499 |

These are three 108-vector runs: eight directed arithmetic cases are repeated per seed, with 100 seeded random rows per run. No coverage percentage is inferred from these counts. Do not claim that Session 4 RTL verification passed until these runs complete.

## Knowledge and interview practice

Review rising-edge handshakes, signed widths, FSM states, blocking versus nonblocking assignment, asynchronous reset, and the distinction between latency and output waiting time.

- Why must a pending input remain stable while input ready is low?
- Why can backpressure delay consumption without changing E0-to-E5 compute latency?
- Why does this single-outstanding controller accept the second input one edge after consuming the first output?
- What should the checker do with an expected result when reset cancels its transaction?
- How does recording a seed and a vector file help reproduce an intermittent failure?
- Why do many passing random tests not prove correctness or establish a coverage percentage?

These checks exercise skills used by RTL designers and verification engineers: reading cycle contracts, building independent checks, diagnosing control bugs, and preserving reproducible failure evidence.
