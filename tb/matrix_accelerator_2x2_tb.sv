`timescale 1ns/1ps

module matrix_accelerator_2x2_tb;

    localparam int IN_WIDTH  = 8;
    localparam int ACC_WIDTH = 32;

    logic clk;
    logic rst_n;

    logic valid_in;
    logic ready_in;

    logic signed [IN_WIDTH-1:0] a00, a01, a10, a11;
    logic signed [IN_WIDTH-1:0] b00, b01, b10, b11;

    logic valid_out;
    logic ready_out;

    logic signed [ACC_WIDTH-1:0] c00, c01, c10, c11;

    logic busy;

    matrix_accelerator_2x2 #(
        .IN_WIDTH(IN_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),

        .valid_in(valid_in),
        .ready_in(ready_in),

        .a00(a00),
        .a01(a01),
        .a10(a10),
        .a11(a11),

        .b00(b00),
        .b01(b01),
        .b10(b10),
        .b11(b11),

        .valid_out(valid_out),
        .ready_out(ready_out),

        .c00(c00),
        .c01(c01),
        .c10(c10),
        .c11(c11),

        .busy(busy)
    );

    always #5 clk = ~clk;

    task automatic tick();
        @(posedge clk);
        #1;
    endtask

    task automatic reset_dut();
        rst_n = 0;
        valid_in = 0;
        ready_out = 0;

        a00 = '0;
        a01 = '0;
        a10 = '0;
        a11 = '0;

        b00 = '0;
        b01 = '0;
        b10 = '0;
        b11 = '0;

        repeat (2) tick();

        rst_n = 1;
        tick();
    endtask

    task automatic drive_matrix_values(
        input logic signed [IN_WIDTH-1:0] in_a00,
        input logic signed [IN_WIDTH-1:0] in_a01,
        input logic signed [IN_WIDTH-1:0] in_a10,
        input logic signed [IN_WIDTH-1:0] in_a11,

        input logic signed [IN_WIDTH-1:0] in_b00,
        input logic signed [IN_WIDTH-1:0] in_b01,
        input logic signed [IN_WIDTH-1:0] in_b10,
        input logic signed [IN_WIDTH-1:0] in_b11
    );
        a00 = in_a00;
        a01 = in_a01;
        a10 = in_a10;
        a11 = in_a11;

        b00 = in_b00;
        b01 = in_b01;
        b10 = in_b10;
        b11 = in_b11;
    endtask

    task automatic send_matrix(
        input logic signed [IN_WIDTH-1:0] in_a00,
        input logic signed [IN_WIDTH-1:0] in_a01,
        input logic signed [IN_WIDTH-1:0] in_a10,
        input logic signed [IN_WIDTH-1:0] in_a11,

        input logic signed [IN_WIDTH-1:0] in_b00,
        input logic signed [IN_WIDTH-1:0] in_b01,
        input logic signed [IN_WIDTH-1:0] in_b10,
        input logic signed [IN_WIDTH-1:0] in_b11
    );
        wait (ready_in == 1'b1);
        #1;

        drive_matrix_values(
            in_a00, in_a01, in_a10, in_a11,
            in_b00, in_b01, in_b10, in_b11
        );

        valid_in = 1'b1;
        tick();
        valid_in = 1'b0;
    endtask

    task automatic wait_valid_output();
        wait (valid_out == 1'b1);
        #1;
    endtask

    task automatic accept_output();
        ready_out = 1'b1;
        tick();
        ready_out = 1'b0;
    endtask

    task automatic check_matrix(
        input logic signed [ACC_WIDTH-1:0] exp_c00,
        input logic signed [ACC_WIDTH-1:0] exp_c01,
        input logic signed [ACC_WIDTH-1:0] exp_c10,
        input logic signed [ACC_WIDTH-1:0] exp_c11,
        input string test_name
    );
        if ((c00 !== exp_c00) ||
            (c01 !== exp_c01) ||
            (c10 !== exp_c10) ||
            (c11 !== exp_c11)) begin

            $display("FAIL: %s", test_name);
            $display("Expected: [%0d %0d; %0d %0d]", exp_c00, exp_c01, exp_c10, exp_c11);
            $display("Got:      [%0d %0d; %0d %0d]", c00, c01, c10, c11);
            $fatal;
        end else begin
            $display("PASS: %s | C = [%0d %0d; %0d %0d]", test_name, c00, c01, c10, c11);
        end
    endtask

    task automatic check_signal(
        input logic actual,
        input logic expected,
        input string test_name
    );
        if (actual !== expected) begin
            $display("FAIL: %s | expected=%0b, got=%0b", test_name, expected, actual);
            $fatal;
        end else begin
            $display("PASS: %s", test_name);
        end
    endtask

    initial begin
        $display("Starting 2x2 matrix accelerator robust handshake testbench...");

        clk = 0;
        reset_dut();

        check_signal(ready_in, 1'b1, "ready_in high after reset");
        check_signal(valid_out, 1'b0, "valid_out low after reset");

        // ------------------------------------------------------------
        // Test 1: Normal valid/ready operation
        // A = [1 2; 3 4]
        // B = [5 6; 7 8]
        // C = [19 22; 43 50]
        // ------------------------------------------------------------
        send_matrix(
            8'sd1, 8'sd2, 8'sd3, 8'sd4,
            8'sd5, 8'sd6, 8'sd7, 8'sd8
        );

        check_signal(ready_in, 1'b0, "ready_in low while accelerator is busy");

        wait_valid_output();

        check_matrix(
            32'sd19,
            32'sd22,
            32'sd43,
            32'sd50,
            "positive matrix with valid/ready handshake"
        );

        accept_output();

        check_signal(ready_in, 1'b1, "ready_in returns high after output accepted");

        // ------------------------------------------------------------
        // Test 2: Output backpressure
        // Keep ready_out low and verify valid_out remains high.
        // ------------------------------------------------------------
        send_matrix(
            -8'sd1,  8'sd2,  8'sd3, -8'sd4,
             8'sd5, -8'sd6, -8'sd7,  8'sd8
        );

        wait_valid_output();

        check_matrix(
            -32'sd19,
             32'sd22,
             32'sd43,
            -32'sd50,
            "signed matrix before backpressure hold"
        );

        ready_out = 1'b0;

        repeat (3) begin
            tick();
            check_signal(valid_out, 1'b1, "valid_out remains high while ready_out is low");
            check_signal(ready_in, 1'b0, "ready_in remains low while output is waiting");

            check_matrix(
                -32'sd19,
                 32'sd22,
                 32'sd43,
                -32'sd50,
                "output data remains stable during backpressure"
            );
        end

        accept_output();

        check_signal(ready_in, 1'b1, "ready_in high after backpressured output accepted");

        // ------------------------------------------------------------
        // Test 3: Input attempted while busy should not be accepted.
        // First send a real matrix, then try to send a different matrix
        // while ready_in is low. The final result should still be from
        // the first matrix.
        // ------------------------------------------------------------
        send_matrix(
            8'sd1, 8'sd0, 8'sd0, 8'sd1,
            8'sd9, 8'sd8, 8'sd7, 8'sd6
        );

        check_signal(ready_in, 1'b0, "ready_in low immediately after input accepted");

        // Attempt to overwrite inputs while busy.
        drive_matrix_values(
            8'sd10, 8'sd10, 8'sd10, 8'sd10,
            8'sd10, 8'sd10, 8'sd10, 8'sd10
        );

        valid_in = 1'b1;
        tick();
        valid_in = 1'b0;

        wait_valid_output();

        // Since first A was identity, C should equal first B:
        // C = [9 8; 7 6]
        check_matrix(
            32'sd9,
            32'sd8,
            32'sd7,
            32'sd6,
            "input while busy is ignored"
        );

        accept_output();

        $display("All robust handshake tests passed.");
        $finish;
    end

endmodule