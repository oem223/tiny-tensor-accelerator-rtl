`timescale 1ns/1ps

// Verification-only checker for the current one-outstanding accelerator.
// Immediate assertions sample BEFORE rising-edge nonblocking RTL updates.
// Reset cancels the pending transaction and both stall-history obligations.
// This is a custom-interface checker, not a generic AXI checker.
module accelerator_protocol_checker #(
    parameter int INPUT_BITS = 64,
    parameter int OUTPUT_BITS = 128,
    parameter int RESULT_LATENCY = 5
)(
    input logic clk, rst_n,
    input logic valid_in, ready_in,
    input logic [INPUT_BITS-1:0] input_payload,
    input logic valid_out, ready_out,
    input logic [OUTPUT_BITS-1:0] output_payload,
    input logic busy
);
    bit pending;
    bit input_was_stalled, output_was_stalled;
    logic [INPUT_BITS-1:0] previous_input;
    logic [OUTPUT_BITS-1:0] previous_output;
    integer age;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending = 1'b0;
            age = 0;
            input_was_stalled = 1'b0;
            output_was_stalled = 1'b0;
            previous_input = '0;
            previous_output = '0;
        end else begin
            a_known_controls: assert ((^{valid_in, ready_in, valid_out, ready_out, busy}) !== 1'bx)
                else $fatal(1, "CHECKER: unknown interface control");

            // An offered transaction must survive the entire stall, including
            // the edge on which READY rises and the transfer finally happens.
            if (input_was_stalled) begin
                a_input_hold: assert (valid_in === 1'b1 && input_payload === previous_input)
                    else $fatal(1, "CHECKER: input changed or VALID dropped after stall");
            end
            if (output_was_stalled) begin
                a_output_hold: assert (valid_out === 1'b1 && output_payload === previous_output)
                    else $fatal(1, "CHECKER: output changed or VALID dropped after stall");
            end
            if (valid_in) begin
                a_known_input: assert ((^input_payload) !== 1'bx)
                    else $fatal(1, "CHECKER: unknown valid input payload");
            end
            if (valid_out) begin
                a_known_output: assert ((^output_payload) !== 1'bx)
                    else $fatal(1, "CHECKER: unknown valid output payload");
            end

            if (pending) begin
                a_one_outstanding: assert (ready_in === 1'b0 && busy === 1'b1)
                    else $fatal(1, "CHECKER: accepted transaction lost or input ready while pending");
                age = age + 1;
                // E0 accepts input, valid_out is registered AFTER E5.
                // The first pre-edge sample seeing it high is E6.
                if (age <= RESULT_LATENCY) begin
                    a_no_early_output: assert (valid_out === 1'b0)
                        else $fatal(1, "CHECKER: output too early, sampled age=%0d", age);
                end else begin
                    a_output_due: assert (valid_out === 1'b1)
                        else $fatal(1, "CHECKER: output missing or late, sampled age=%0d", age);
                end
            end else begin
                a_idle: assert (ready_in === 1'b1 && busy === 1'b0 && valid_out === 1'b0)
                    else $fatal(1, "CHECKER: non-idle interface without an accepted transaction");
            end

            if (valid_out && ready_out)
                pending = 1'b0;
            if (valid_in && ready_in) begin
                pending = 1'b1;
                age = 0;
            end

            input_was_stalled = valid_in && !ready_in;
            output_was_stalled = valid_out && !ready_out;
            previous_input = input_payload;
            previous_output = output_payload;
        end
    end
endmodule
