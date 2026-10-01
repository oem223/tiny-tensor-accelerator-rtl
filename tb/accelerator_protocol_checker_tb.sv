`timescale 1ns/1ps

// Synthetic legal/illegal interface traces exercise the checker itself.
// No arithmetic DUT here: reference-vector tests cover the actual RTL.
module accelerator_protocol_checker_tb;
    logic clk = 1'b0, rst_n = 1'b0;
    logic valid_in = 1'b0, ready_in = 1'b1;
    logic valid_out = 1'b0, ready_out = 1'b0, busy = 1'b0;
    logic [63:0] input_payload = '0;
    logic [127:0] output_payload = '0;
    integer fault = 0;

    accelerator_protocol_checker checker_inst (.*);
    always #5 clk = ~clk;

    task automatic tick();
        @(posedge clk);
        #1; // Drive only after the checker's pre-edge sample.
    endtask

    initial begin
        #1000;
        $fatal(1, "FAIL: checker self-test timeout");
    end

    initial begin
        if ($value$plusargs("FAULT=%d", fault)) begin
            if (fault < 0 || fault > 3)
                $fatal(1, "FAIL: FAULT must be 0, 1, 2, or 3");
        end
        repeat (2) @(negedge clk);
        rst_n = 1'b1;
        @(negedge clk);
        valid_in = 1'b1;
        input_payload = 64'h0102030405060708;

        tick(); // E0: input accepted.
        valid_in = 1'b0;
        ready_in = 1'b0;
        busy = 1'b1;
        repeat (4) tick(); // Through E4.
        if (fault == 3) begin
            valid_out = 1'b1; // Too early: high before E5.
            output_payload = 128'h13;
        end
        tick(); // E5: legal result becomes valid after this edge.
        valid_out = 1'b1;
        output_payload = 128'h13;
        valid_in = 1'b1; // A second source transaction waits while busy.
        input_payload = 64'h1112131415161718;

        tick(); // E6: both input and output are stalled.
        @(negedge clk);
        if (fault == 1)
            output_payload = 128'h14;
        if (fault == 2)
            valid_in = 1'b0;
        tick(); // E7: injected faults 1/2 must be caught here.
        @(negedge clk);
        ready_out = 1'b1;
        tick(); // E8: first output consumed, second input still pending.
        valid_out = 1'b0;
        ready_in = 1'b1;
        busy = 1'b0;
        tick(); // E9: second input accepted.
        valid_in = 1'b0;
        ready_in = 1'b0;
        busy = 1'b1;

        #1; // Asynchronous reset cancels the accepted second transaction.
        rst_n = 1'b0;
        ready_in = 1'b1;
        busy = 1'b0;
        output_payload = '0;
        @(negedge clk);
        rst_n = 1'b1;
        tick();
        if (fault != 0)
            $fatal(1, "FAIL: injected fault %0d escaped the checker", fault);
        $display("PASS: protocol checker legal trace, stalls, pending input, and reset cancellation");
        $finish;
    end
endmodule
