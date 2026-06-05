module matrix_mult_2x2 #(
    parameter int IN_WIDTH  = 8,
    parameter int ACC_WIDTH = 32
)(
    input  logic clk,
    input  logic rst_n,

    input  logic start,

    input  logic signed [IN_WIDTH-1:0] a00,
    input  logic signed [IN_WIDTH-1:0] a01,
    input  logic signed [IN_WIDTH-1:0] a10,
    input  logic signed [IN_WIDTH-1:0] a11,

    input  logic signed [IN_WIDTH-1:0] b00,
    input  logic signed [IN_WIDTH-1:0] b01,
    input  logic signed [IN_WIDTH-1:0] b10,
    input  logic signed [IN_WIDTH-1:0] b11,

    output logic busy,
    output logic done,

    output logic signed [ACC_WIDTH-1:0] c00,
    output logic signed [ACC_WIDTH-1:0] c01,
    output logic signed [ACC_WIDTH-1:0] c10,
    output logic signed [ACC_WIDTH-1:0] c11
);

    typedef enum logic [2:0] {
        S_IDLE,
        S_CLEAR,
        S_COMPUTE_K0,
        S_COMPUTE_K1,
        S_DONE
    } state_t;

    state_t state;

    logic signed [IN_WIDTH-1:0] a00_r, a01_r, a10_r, a11_r;
    logic signed [IN_WIDTH-1:0] b00_r, b01_r, b10_r, b11_r;

    logic clear_macs;
    logic enable_macs;

    logic signed [IN_WIDTH-1:0] mac00_a, mac00_b;
    logic signed [IN_WIDTH-1:0] mac01_a, mac01_b;
    logic signed [IN_WIDTH-1:0] mac10_a, mac10_b;
    logic signed [IN_WIDTH-1:0] mac11_a, mac11_b;

    logic signed [ACC_WIDTH-1:0] acc00;
    logic signed [ACC_WIDTH-1:0] acc01;
    logic signed [ACC_WIDTH-1:0] acc10;
    logic signed [ACC_WIDTH-1:0] acc11;

    assign c00 = acc00;
    assign c01 = acc01;
    assign c10 = acc10;
    assign c11 = acc11;

    assign busy = (state != S_IDLE) && (state != S_DONE);
    assign done = (state == S_DONE);

    mac_unit #(
        .IN_WIDTH(IN_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) mac00 (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear_macs),
        .enable(enable_macs),
        .a(mac00_a),
        .b(mac00_b),
        .acc(acc00)
    );

    mac_unit #(
        .IN_WIDTH(IN_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) mac01 (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear_macs),
        .enable(enable_macs),
        .a(mac01_a),
        .b(mac01_b),
        .acc(acc01)
    );

    mac_unit #(
        .IN_WIDTH(IN_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) mac10 (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear_macs),
        .enable(enable_macs),
        .a(mac10_a),
        .b(mac10_b),
        .acc(acc10)
    );

    mac_unit #(
        .IN_WIDTH(IN_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) mac11 (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear_macs),
        .enable(enable_macs),
        .a(mac11_a),
        .b(mac11_b),
        .acc(acc11)
    );

    always_comb begin
        clear_macs = 1'b0;
        enable_macs = 1'b0;

        mac00_a = '0;
        mac00_b = '0;
        mac01_a = '0;
        mac01_b = '0;
        mac10_a = '0;
        mac10_b = '0;
        mac11_a = '0;
        mac11_b = '0;

        case (state)
            S_CLEAR: begin
                clear_macs = 1'b1;
            end

            S_COMPUTE_K0: begin
                enable_macs = 1'b1;

                mac00_a = a00_r;
                mac00_b = b00_r;

                mac01_a = a00_r;
                mac01_b = b01_r;

                mac10_a = a10_r;
                mac10_b = b00_r;

                mac11_a = a10_r;
                mac11_b = b01_r;
            end

            S_COMPUTE_K1: begin
                enable_macs = 1'b1;

                mac00_a = a01_r;
                mac00_b = b10_r;

                mac01_a = a01_r;
                mac01_b = b11_r;

                mac10_a = a11_r;
                mac10_b = b10_r;

                mac11_a = a11_r;
                mac11_b = b11_r;
            end

            default: begin
                // keep defaults
            end
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;

            a00_r <= '0;
            a01_r <= '0;
            a10_r <= '0;
            a11_r <= '0;

            b00_r <= '0;
            b01_r <= '0;
            b10_r <= '0;
            b11_r <= '0;
        end else begin
            case (state)
                S_IDLE: begin
                    if (start) begin
                        a00_r <= a00;
                        a01_r <= a01;
                        a10_r <= a10;
                        a11_r <= a11;

                        b00_r <= b00;
                        b01_r <= b01;
                        b10_r <= b10;
                        b11_r <= b11;

                        state <= S_CLEAR;
                    end
                end

                S_CLEAR: begin
                    state <= S_COMPUTE_K0;
                end

                S_COMPUTE_K0: begin
                    state <= S_COMPUTE_K1;
                end

                S_COMPUTE_K1: begin
                    state <= S_DONE;
                end

                S_DONE: begin
                    state <= S_IDLE;
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule