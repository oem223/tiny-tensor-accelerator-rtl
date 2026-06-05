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

        a00 = in_a00;
        a01 = in_a01;
        a10 = in_a10;
        a11 = in_a11;

        b00 = in_b00;
        b01 = in_b01;
        b10 = in_b10;
        b11 = in_b11;

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

    initial begin
        $display("Starting 2x2 matrix accelerator handshake testbench...");

        clk = 0;
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

        if (ready_in !== 1'b1) begin
            $display("FAIL: ready_in should be high after reset");
            $fatal;
        end else begin
            $display("PASS: ready_in high after reset");
        end

        // Test 1:
        // A = [1 2; 3 4]
        // B = [5 6; 7 8]
        // C = [19 22; 43 50]
        send_matrix(
            8'sd1, 8'sd2, 8'sd3, 8'sd4,
            8'sd5, 8'sd6, 8'sd7, 8'sd8
        );

        wait_valid_output();

        check_matrix(
            32'sd19,
            32'sd22,
            32'sd43,
            32'sd50,
            "positive matrix with valid/ready handshake"
        );

        accept_output();

        if (ready_in !== 1'b1) begin
            $display("FAIL: ready_in should return high after output accepted");
            $fatal;
        end else begin
            $display("PASS: ready_in returns high after output accepted");
        end

        // Test 2:
        // A = [-1 2; 3 -4]
        // B = [5 -6; -7 8]
        // C = [-19 22; 43 -50]
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
            "signed matrix with valid/ready handshake"
        );

        accept_output();

        $display("All 2x2 matrix accelerator handshake tests passed.");
        $finish;
    end

endmodule