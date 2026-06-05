`timescale 1ns/1ps

module matrix_mult_2x2_tb;

    localparam int IN_WIDTH  = 8;
    localparam int ACC_WIDTH = 32;

    logic clk;
    logic rst_n;
    logic start;
    logic busy;
    logic done;

    logic signed [IN_WIDTH-1:0] a00, a01, a10, a11;
    logic signed [IN_WIDTH-1:0] b00, b01, b10, b11;

    logic signed [ACC_WIDTH-1:0] c00, c01, c10, c11;

    matrix_mult_2x2 #(
        .IN_WIDTH(IN_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),

        .a00(a00),
        .a01(a01),
        .a10(a10),
        .a11(a11),

        .b00(b00),
        .b01(b01),
        .b10(b10),
        .b11(b11),

        .busy(busy),
        .done(done),

        .c00(c00),
        .c01(c01),
        .c10(c10),
        .c11(c11)
    );

    always #5 clk = ~clk;

    task automatic tick();
        @(posedge clk);
        #1;
    endtask

    task automatic start_operation();
        start = 1'b1;
        tick();
        start = 1'b0;
    endtask

    task automatic wait_done();
        wait (done == 1'b1);
        #1;
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
        $display("Starting 2x2 matrix multiplier testbench...");

        clk = 0;
        rst_n = 0;
        start = 0;

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

        // Test 1:
        // A = [1 2; 3 4]
        // B = [5 6; 7 8]
        // C = [19 22; 43 50]
        a00 = 8'sd1;
        a01 = 8'sd2;
        a10 = 8'sd3;
        a11 = 8'sd4;

        b00 = 8'sd5;
        b01 = 8'sd6;
        b10 = 8'sd7;
        b11 = 8'sd8;

        start_operation();
        wait_done();

        check_matrix(
            32'sd19,
            32'sd22,
            32'sd43,
            32'sd50,
            "positive 2x2 matrix multiplication"
        );

        tick();

        // Test 2:
        // A = [-1 2; 3 -4]
        // B = [5 -6; -7 8]
        // C = [-19 22; 43 -50]
        a00 = -8'sd1;
        a01 =  8'sd2;
        a10 =  8'sd3;
        a11 = -8'sd4;

        b00 =  8'sd5;
        b01 = -8'sd6;
        b10 = -8'sd7;
        b11 =  8'sd8;

        start_operation();
        wait_done();

        check_matrix(
            -32'sd19,
             32'sd22,
             32'sd43,
            -32'sd50,
            "signed 2x2 matrix multiplication"
        );

        $display("All 2x2 matrix multiplier tests passed.");
        $finish;
    end

endmodule