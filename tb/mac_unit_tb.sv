`timescale 1ns/1ps

module mac_unit_tb;

    localparam int IN_WIDTH  = 8;
    localparam int ACC_WIDTH = 32;

    logic clk;
    logic rst_n;
    logic clear;
    logic enable;

    logic signed [IN_WIDTH-1:0] a;
    logic signed [IN_WIDTH-1:0] b;
    logic signed [ACC_WIDTH-1:0] acc;

    mac_unit #(
        .IN_WIDTH(IN_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),
        .enable(enable),
        .a(a),
        .b(b),
        .acc(acc)
    );

    always #5 clk = ~clk;

    task automatic tick();
        @(posedge clk);
        #1;
    endtask

    task automatic check_acc(
        input logic signed [ACC_WIDTH-1:0] expected,
        input string test_name
    );
        if (acc !== expected) begin
            $display("FAIL: %s | expected=%0d, got=%0d", test_name, expected, acc);
            $fatal;
        end else begin
            $display("PASS: %s | acc=%0d", test_name, acc);
        end
    endtask

    initial begin
        $display("Starting MAC unit testbench...");

        clk    = 0;
        rst_n  = 0;
        clear  = 0;
        enable = 0;
        a      = '0;
        b      = '0;

        repeat (2) tick();

        rst_n = 1;
        tick();
        check_acc(32'sd0, "reset clears accumulator");

        enable = 1;
        a = 8'sd2;
        b = 8'sd3;
        tick();
        check_acc(32'sd6, "2*3 = 6");

        a = 8'sd4;
        b = 8'sd5;
        tick();
        check_acc(32'sd26, "6 + 4*5 = 26");

        enable = 0;
        a = 8'sd100;
        b = 8'sd100;
        tick();
        check_acc(32'sd26, "enable=0 keeps accumulator unchanged");

        clear = 1;
        tick();
        check_acc(32'sd0, "clear resets accumulator");

        clear = 0;
        enable = 1;
        a = -8'sd3;
        b = 8'sd4;
        tick();
        check_acc(-32'sd12, "-3*4 = -12");

        a = -8'sd2;
        b = -8'sd5;
        tick();
        check_acc(-32'sd2, "-12 + (-2*-5) = -2");

        $display("All MAC unit tests passed.");
        $finish;
    end

endmodule