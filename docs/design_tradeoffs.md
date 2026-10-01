# Design tradeoffs: current 2x2 baseline

This review records why the current RTL is useful, what limits it, and what would need to change for another goal. Alternatives below are architectural expectations, not synthesized comparisons. Only the default signed 8-bit input / 32-bit accumulator configuration has simulation evidence.

## Performance terms and exact edge sequence

An input transfer happens at a rising edge with `valid_in && ready_in`. Result latency ends when `valid_out` becomes high, even if the receiver is stalled. Initiation interval is the number of clock periods between successive accepted input transactions under the specified traffic conditions.

| Quantity | Current RTL | Basis |
| --- | --- | --- |
| Arithmetic update edges per matrix | 2 | Four MACs update at K0 and K1. |
| Inner-core start-to-done latency | 3 clock periods | Capture, clear, K0, K1; done rises after K1. |
| Top-level input-to-valid latency | 5 clock periods | E0 input capture through E5 output capture; checked by Sessions 3/4. |
| Minimum top-level initiation interval | 7 clock periods | Derived from E0 accept, E5 result valid, E6 consume, E7 next accept. Requires a waiting source and always-ready receiver. |
| Ideal matrix throughput | `f_clk / 7` | Derived bound for this controller, without stalls or source gaps. An achieved `f_clk` has not been measured. |

The result cannot be consumed at E5: `valid_out` was low before that edge and rises only after the sequential update. `ready_in` remains low before E6, so the next input cannot be accepted on the output-consumption edge. An output stall increases the interval before the next input; it does not change the E0-to-E5 result-production latency.

## Architecture decisions

| Decision | Benefit | Cost / alternative |
| --- | --- | --- |
| Four MACs, one per output element | Simple mapping; all four outputs accumulate in parallel over two arithmetic updates. | A one-MAC design needs eight product updates plus selection/control. It may reduce arithmetic resources but raises latency. Total latency depends on the actual controller. |
| Reuse each multiplier for K0 and K1 | Fewer multipliers than an eight-product parallel datapath. | An eight-multiplier/four-adder design could produce products in parallel, at greater expected resource cost. Pipeline depth and clock timing determine its actual latency and throughput. |
| One transaction outstanding | Small FSM, straightforward ordering, reset cancellation, and result tracking. | Computation cannot overlap an unconsumed output or the next transaction. A queue alone does not fix this; the controller must support overlap and track storage ownership. |
| Separate outer controller and inner compute core | Distinct transaction and arithmetic responsibilities; independently understandable modules. | Registered start handoff and result capture add latency. Both layers also capture inputs: 64 input bits per layer at defaults, before synthesis optimization. |
| 32-bit accumulation/output | Exact default arithmetic with headroom and a convenient result width. | 17 signed bits suffice for this exact 2x2/8-bit operation. Wider accumulators/registers may cost resources or timing. Alternate widths are not yet qualified. |
| Explicit accumulator clear cycle | Each computation starts from zero; MAC clear/enable behavior is easy to verify. | Adds a cycle. Loading the first product directly would require an RTL change and new verification. |
| Registered output held under backpressure | Receiver can pause without losing the result; output values stay stable. | Output storage and a busy period until consumption. An adapter must preserve this behavior. |

Four logical MAC instances do not necessarily mean four physical FPGA DSP blocks. Synthesis maps multiplication widths, accumulation, reset, and enables to the selected device; resource reports must establish the actual mapping.

## Signed-width reasoning

Signed 8-bit inputs range from -128 to 127. One product ranges from -16256 to 16384. The sum of two products can reach 32768, as with two `(-128)*(-128)` products. A signed 16-bit value stops at 32767, so 17 bits are needed for every possible result. In general, exact two-product accumulation requires `ACC_WIDTH >= 2*IN_WIDTH + 1`.

The RTL currently lacks parameter guards and the tests qualify only 8/32. Do not infer larger-matrix support from the 32-bit accumulator: matrix dimensions, operand delivery, and control would also need changes.

## Paths and synthesis questions for Session 6

A timing path connects a launching register/input to a capturing register/output through combinational logic. A plausible datapath path here includes operand selection, multiplication, addition, and the accumulator register. The actual critical path is the path with the worst timing slack in the constrained implementation; it may be elsewhere and must be read from the report.

Adding registers can shorten combinational paths and improve an achievable clock, but adds latency/control requirements. Pipelining this datapath alone does not guarantee one matrix per cycle while the top-level controller allows only one outstanding transaction.

Session 6 will record the exact FPGA part, Quartus version, clock and I/O constraints, resource mapping, post-fit timing, and any unconstrained paths. Until then, this document supports architectural reasoning, not measured area, power, frequency, or ASIC sign-off claims.

## Interview practice

Explain, using the RTL rather than memorized numbers:

1. Why are there four MACs but two compute edges? What changes with one MAC?
2. Why is result latency five periods while initiation interval is seven?
3. Can the next input transfer on the same edge as the current output? Why?
4. Why does signed 8-bit multiplication followed by two-term addition require 17 bits?
5. Would an output FIFO automatically increase throughput? What controller changes are needed?
6. Which report would establish that a proposed pipeline actually improves timing?