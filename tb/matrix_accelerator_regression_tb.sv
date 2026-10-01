`timescale 1ns/1ps

// One outstanding result: expected values are read from the Python oracle.
// Drive at falling edges; sample after rising-edge nonblocking updates settle.
module matrix_accelerator_regression_tb;
    localparam int RESULT_LATENCY = 5;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic valid_in = 1'b0;
    logic ready_in;
    logic ready_out = 1'b0;
    logic valid_out;
    logic busy;
    logic signed [7:0] a00, a01, a10, a11, b00, b01, b10, b11;
    logic signed [31:0] c00, c01, c10, c11;

    integer vector_file, fields, seed, declared_cases;
    integer case_number = 0;
    integer va00, va01, va10, va11, vb00, vb01, vb10, vb11;
    integer ec00, ec01, ec10, ec11, input_gap, output_stall;
    integer accepted_count = 0;
    integer consumed_count = 0;
    integer checked_count = 0;
    integer cancelled_count = 0;
    integer always_ready_count = 0;
    integer short_stall_count = 0;
    integer long_stall_count = 0;
    integer gap_count = 0;
    integer stalled_edges = 0;
    integer reset_count = 0;
    string vector_path;

    matrix_accelerator_2x2 dut (
        .clk(clk), .rst_n(rst_n),
        .valid_in(valid_in), .ready_in(ready_in),
        .a00(a00), .a01(a01), .a10(a10), .a11(a11),
        .b00(b00), .b01(b01), .b10(b10), .b11(b11),
        .valid_out(valid_out), .ready_out(ready_out),
        .c00(c00), .c01(c01), .c10(c10), .c11(c11), .busy(busy)
    );

    always #5 clk = ~clk;

    // Count actual pre-edge handshakes, including inputs held pending while busy.
    always @(posedge clk) begin
        if (rst_n) begin
            if (valid_in && ready_in) accepted_count++;
            if (valid_out && ready_out) consumed_count++;
        end
    end

    initial begin
        #10000000;
        $fatal(1, "FAIL: regression timeout seed=%0d case=%0d", seed, case_number);
    end

    task automatic tick();
        @(posedge clk);
        #1;
    endtask

    task automatic expect_idle(input string phase);
        if (ready_in !== 1'b1 || valid_out !== 1'b0 || busy !== 1'b0)
            $fatal(1, "FAIL: seed=%0d case=%0d %s: ready_in=%b valid_out=%b busy=%b",
                seed, case_number, phase, ready_in, valid_out, busy);
    endtask

    task automatic check_output(
        input integer x00, x01, x10, x11, input string phase
    );
        if (c00 !== x00 || c01 !== x01 || c10 !== x10 || c11 !== x11)
            $fatal(1,
                "FAIL: seed=%0d case=%0d %s A=[%0d %0d; %0d %0d] B=[%0d %0d; %0d %0d] expected=[%0d %0d; %0d %0d] got=[%0d %0d; %0d %0d]",
                seed, case_number, phase, va00, va01, va10, va11,
                vb00, vb01, vb10, vb11, x00, x01, x10, x11, c00, c01, c10, c11);
    endtask

    task automatic drive_row();
        a00 = va00; a01 = va01; a10 = va10; a11 = va11;
        b00 = vb00; b01 = vb01; b10 = vb10; b11 = vb11;
    endtask

    task automatic load_positive();
        va00 = 1; va01 = 2; va10 = 3; va11 = 4;
        vb00 = 5; vb01 = 6; vb10 = 7; vb11 = 8;
        ec00 = 19; ec01 = 22; ec10 = 43; ec11 = 50;
    endtask

    task automatic load_identity();
        va00 = 1; va01 = 0; va10 = 0; va11 = 1;
        vb00 = 9; vb01 = 8; vb10 = 7; vb11 = 6;
        ec00 = 9; ec01 = 8; ec10 = 7; ec11 = 6;
    endtask

    task automatic launch_row(input bit receiver_ready);
        @(negedge clk);
        expect_idle("before launch");
        ready_out = receiver_ready;
        drive_row();
        valid_in = 1'b1;
        tick(); // E0
        if (ready_in !== 1'b0 || busy !== 1'b1 || valid_out !== 1'b0)
            $fatal(1, "FAIL: seed=%0d case=%0d input not captured at E0", seed, case_number);
        @(negedge clk);
        valid_in = 1'b0;
    endtask

    task automatic await_row();
        for (int cycle = 1; cycle <= RESULT_LATENCY; cycle++) begin
            tick();
            if (valid_out !== (cycle == RESULT_LATENCY) || ready_in !== 1'b0 || busy !== 1'b1)
                $fatal(1, "FAIL: seed=%0d case=%0d interface at E%0d", seed, case_number, cycle);
        end
        check_output(ec00, ec01, ec10, ec11, "result at E5");
    endtask

    task automatic run_row(input integer gap_cycles, stall_cycles);
        repeat (gap_cycles) begin
            tick();
            expect_idle("input gap");
        end
        launch_row(stall_cycles == 0);
        await_row();
        repeat (stall_cycles) begin
            tick();
            if (valid_out !== 1'b1 || ready_in !== 1'b0 || busy !== 1'b1)
                $fatal(1, "FAIL: seed=%0d case=%0d output lost during stall", seed, case_number);
            check_output(ec00, ec01, ec10, ec11, "output stall");
        end
        if (stall_cycles != 0) begin
            @(negedge clk);
            ready_out = 1'b1;
        end
        tick(); // The pre-edge valid && ready consumes the result.
        expect_idle("after output consumption");
        checked_count++;
    endtask

    task automatic pending_input_pair();
        load_positive();
        launch_row(1'b0);
        // launch_row returns at E0's falling edge. Offer a second input now,
        // and hold both valid and data until an actual accepting edge.
        a00 = 1; a01 = 0; a10 = 0; a11 = 1;
        b00 = 9; b01 = 8; b10 = 7; b11 = 6;
        valid_in = 1'b1;
        for (int cycle = 1; cycle <= RESULT_LATENCY; cycle++) begin
            tick();
            if (ready_in !== 1'b0 || valid_out !== (cycle == RESULT_LATENCY))
                $fatal(1, "FAIL: pending input accepted too early at E%0d", cycle);
        end
        check_output(19, 22, 43, 50, "first result with second input pending");
        repeat (2) begin
            tick();
            if (valid_out !== 1'b1 || ready_in !== 1'b0)
                $fatal(1, "FAIL: pending input changed stalled first transaction");
            check_output(19, 22, 43, 50, "first result held");
        end
        @(negedge clk);
        ready_out = 1'b1;
        tick(); // First output accepted; ready_in was low before this edge.
        expect_idle("first output accepted with second input pending");
        checked_count++;
        tick(); // Second input accepted on the next edge.
        if (ready_in !== 1'b0 || busy !== 1'b1 || valid_out !== 1'b0)
            $fatal(1, "FAIL: pending second input not accepted after release");
        @(negedge clk);
        valid_in = 1'b0;
        load_identity();
        await_row();
        tick();
        expect_idle("second output consumed");
        checked_count++;
        $display("PASS: pending input held until acceptance; two ordered outputs");
    endtask

    task automatic reset_inflight(input integer elapsed_edges);
        load_positive();
        launch_row(1'b0);
        // launch_row ends at a falling edge, so elapsed_edges=0 resets before E1.
        repeat (elapsed_edges) tick();
        if (ready_in !== 1'b0 || busy !== 1'b1 || valid_out !== (elapsed_edges == 5))
            $fatal(1, "FAIL: unexpected state before reset at E%0d", elapsed_edges);
        #2; // Assert away from the rising edge to exercise asynchronous reset.
        rst_n = 1'b0;
        valid_in = 1'b0;
        ready_out = 1'b0;
        cancelled_count++;
        #1;
        expect_idle("asynchronous reset asserted");
        check_output(0, 0, 0, 0, "reset clears outputs");
        repeat (2) @(negedge clk);
        rst_n = 1'b1;
        // Give an old computation enough time to show up if reset failed.
        repeat (RESULT_LATENCY + 2) begin
            tick();
            expect_idle("no stale result after reset");
            check_output(0, 0, 0, 0, "no stale data after reset");
        end
        load_positive();
        run_row(0, 0); // Check recovery with a new, valid transaction.
        reset_count++;
        $display("PASS: reset after E%0d cancels old transaction; fresh transaction passed", elapsed_edges);
    endtask

    initial begin
        a00 = '0; a01 = '0; a10 = '0; a11 = '0;
        b00 = '0; b01 = '0; b10 = '0; b11 = '0;
        vector_path = "../vectors/regression_2x2.txt";
        if ($value$plusargs("VECTORS=%s", vector_path))
            $display("Using vectors: %s", vector_path);
        vector_file = $fopen(vector_path, "r");
        if (vector_file == 0) $fatal(1, "FAIL: cannot open %s", vector_path);
        fields = $fscanf(vector_file, "seed %d cases %d", seed, declared_cases);
        if (fields != 2 || declared_cases < 8 || declared_cases > 10008)
            $fatal(1, "FAIL: invalid regression header in %s", vector_path);
        $display("Starting Session 4 regression seed=%0d cases=%0d", seed, declared_cases);

        repeat (2) @(negedge clk);
        rst_n = 1'b1;
        tick();
        expect_idle("initial reset release");

        while (1) begin
            fields = $fscanf(vector_file, "%d %d %d %d %d %d %d %d %d %d %d %d %d %d",
                va00, va01, va10, va11, vb00, vb01, vb10, vb11,
                ec00, ec01, ec10, ec11, input_gap, output_stall);
            if (fields == -1 && $feof(vector_file)) break;
            if (fields != 14) $fatal(1, "FAIL: seed=%0d row=%0d expected 14 fields; got %0d",
                seed, case_number + 1, fields);
            if (input_gap < 0 || input_gap > 3 || output_stall < 0 || output_stall > 20)
                $fatal(1, "FAIL: unsupported gap/stall schedule");
            if (va00 < -128 || va00 > 127 || va01 < -128 || va01 > 127 ||
                va10 < -128 || va10 > 127 || va11 < -128 || va11 > 127 ||
                vb00 < -128 || vb00 > 127 || vb01 < -128 || vb01 > 127 ||
                vb10 < -128 || vb10 > 127 || vb11 < -128 || vb11 > 127)
                $fatal(1, "FAIL: input outside signed 8-bit range");
            case_number++;
            run_row(input_gap, output_stall);
            if (input_gap != 0) gap_count++;
            if (output_stall == 0) always_ready_count++;
            else if (output_stall <= 5) short_stall_count++;
            else long_stall_count++;
            stalled_edges += output_stall;
            if (case_number <= 8 || case_number % 25 == 0)
                $display("PASS: seed=%0d case=%0d gap=%0d stall=%0d",
                    seed, case_number, input_gap, output_stall);
        end
        $fclose(vector_file);
        if (case_number != declared_cases)
            $fatal(1, "FAIL: header=%0d rows=%0d", declared_cases, case_number);

        pending_input_pair();
        reset_inflight(0);
        reset_inflight(1);
        reset_inflight(3);
        reset_inflight(4);
        reset_inflight(5);
        repeat (3) begin
            tick();
            expect_idle("final idle: no duplicate result");
        end
        if (accepted_count != checked_count + cancelled_count || consumed_count != checked_count)
            $fatal(1, "FAIL: accounting accepted=%0d consumed=%0d checked=%0d cancelled=%0d",
                accepted_count, consumed_count, checked_count, cancelled_count);
        if (always_ready_count == 0 || short_stall_count == 0 || long_stall_count == 0 || gap_count == 0)
            $fatal(1, "FAIL: a required timing scenario was not exercised");
        $display("SCENARIOS: always_ready=%0d short_stall=%0d long_stall=%0d input_gap=%0d stalled_edges=%0d resets=%0d",
            always_ready_count, short_stall_count, long_stall_count, gap_count, stalled_edges, reset_count);
        $display("ACCOUNTING: accepted=%0d consumed=%0d checked=%0d cancelled=%0d",
            accepted_count, consumed_count, checked_count, cancelled_count);
        $display("PASS: Session 4 seed=%0d vectors=%0d pending_pair=1 reset_scenarios=%0d",
            seed, case_number, reset_count);
        $finish;
    end
endmodule