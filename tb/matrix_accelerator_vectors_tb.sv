`timescale 1ns/1ps

// File-driven arithmetic regression for the default 8-bit/32-bit accelerator.
// Expected results come from the independent Python model, not from RTL math.
module matrix_accelerator_vectors_tb;
    localparam int IN_WIDTH = 8;
    localparam int ACC_WIDTH = 32;
    localparam int RESULT_LATENCY = 5;

    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic valid_in = 1'b0;
    logic ready_in;
    logic ready_out = 1'b0;
    logic valid_out;
    logic busy;
    logic signed [IN_WIDTH-1:0] a00, a01, a10, a11;
    logic signed [IN_WIDTH-1:0] b00, b01, b10, b11;
    logic signed [ACC_WIDTH-1:0] c00, c01, c10, c11;

    integer vector_file;
    integer fields;
    integer case_number = 0;
    integer va00, va01, va10, va11;
    integer vb00, vb01, vb10, vb11;
    integer ec00, ec01, ec10, ec11;
    string vector_path;

    matrix_accelerator_2x2 #(
        .IN_WIDTH(IN_WIDTH), .ACC_WIDTH(ACC_WIDTH)
    ) dut (
        .clk(clk), .rst_n(rst_n),
        .valid_in(valid_in), .ready_in(ready_in),
        .a00(a00), .a01(a01), .a10(a10), .a11(a11),
        .b00(b00), .b01(b01), .b10(b10), .b11(b11),
        .valid_out(valid_out), .ready_out(ready_out),
        .c00(c00), .c01(c01), .c10(c10), .c11(c11),
        .busy(busy)
    );

    always #5 clk = ~clk;

    initial begin
        #10000;
        $fatal(1, "FAIL: vector regression timed out");
    end

    task automatic check_result(input integer index);
        if (c00 !== ec00 || c01 !== ec01 || c10 !== ec10 || c11 !== ec11) begin
            $fatal(1,
                "FAIL: vector %0d A=[%0d %0d; %0d %0d] B=[%0d %0d; %0d %0d] expected=[%0d %0d; %0d %0d] got=[%0d %0d; %0d %0d]",
                index, va00, va01, va10, va11, vb00, vb01, vb10, vb11,
                ec00, ec01, ec10, ec11, c00, c01, c10, c11);
        end
    endtask

    initial begin
        a00 = '0; a01 = '0; a10 = '0; a11 = '0;
        b00 = '0; b01 = '0; b10 = '0; b11 = '0;

        vector_path = "../vectors/directed_2x2.txt";
        if ($value$plusargs("VECTORS=%s", vector_path)) begin
            $display("Using vector override: %s", vector_path);
        end
        vector_file = $fopen(vector_path, "r");
        if (vector_file == 0)
            $fatal(1, "FAIL: cannot open %s (run from sim/ or use +VECTORS=path)", vector_path);

        repeat (2) @(negedge clk);
        rst_n = 1'b1;
        @(negedge clk);
        if (ready_in !== 1'b1 || valid_out !== 1'b0)
            $fatal(1, "FAIL: unexpected interface state after reset");

        while (1) begin
            fields = $fscanf(vector_file,
                "%d %d %d %d %d %d %d %d %d %d %d %d",
                va00, va01, va10, va11, vb00, vb01, vb10, vb11,
                ec00, ec01, ec10, ec11);
            if (fields == -1 && $feof(vector_file))
                break;
            if (fields != 12)
                $fatal(1, "FAIL: expected 12 decimal fields in vector %0d; read %0d",
                    case_number + 1, fields);
            case_number++;

            // Drive before the accepting edge; the DUT samples only valid && ready.
            @(negedge clk);
            if (ready_in !== 1'b1 || valid_out !== 1'b0)
                $fatal(1, "FAIL: vector %0d cannot start", case_number);
            a00 = va00; a01 = va01; a10 = va10; a11 = va11;
            b00 = vb00; b01 = vb01; b10 = vb10; b11 = vb11;
            valid_in = 1'b1;
            @(posedge clk); // E0: accepted input
            #1;
            if (ready_in !== 1'b0 || busy !== 1'b1)
                $fatal(1, "FAIL: vector %0d not captured at E0", case_number);
            valid_in = 1'b0;

            // The current interface contract specifies valid_out at E5.
            for (int cycle = 1; cycle <= RESULT_LATENCY; cycle++) begin
                @(posedge clk);
                #1;
                if (valid_out !== (cycle == RESULT_LATENCY))
                    $fatal(1, "FAIL: vector %0d valid_out at E%0d is %b",
                        case_number, cycle, valid_out);
            end
            check_result(case_number);

            // Hold each result for two extra cycles to exercise backpressure.
            repeat (2) begin
                @(posedge clk);
                #1;
                if (valid_out !== 1'b1 || ready_in !== 1'b0)
                    $fatal(1, "FAIL: vector %0d lost output while stalled", case_number);
                check_result(case_number);
            end

            @(negedge clk);
            ready_out = 1'b1;
            @(posedge clk); // Consume result.
            #1;
            if (valid_out !== 1'b0 || ready_in !== 1'b1)
                $fatal(1, "FAIL: vector %0d did not release output", case_number);
            ready_out = 1'b0;
            $display("PASS: vector %0d expected=[%0d %0d; %0d %0d]",
                case_number, ec00, ec01, ec10, ec11);
        end

        $fclose(vector_file);
        if (case_number == 0)
            $fatal(1, "FAIL: no vectors in %s", vector_path);
        $display("PASS: %0d Python reference vectors matched RTL", case_number);
        $finish;
    end
endmodule
