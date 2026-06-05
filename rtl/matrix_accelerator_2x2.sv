module matrix_accelerator_2x2 #(
    parameter int IN_WIDTH  = 8,
    parameter int ACC_WIDTH = 32
)(
    input  logic clk,
    input  logic rst_n,

    input  logic valid_in,
    output logic ready_in,

    input  logic signed [IN_WIDTH-1:0] a00,
    input  logic signed [IN_WIDTH-1:0] a01,
    input  logic signed [IN_WIDTH-1:0] a10,
    input  logic signed [IN_WIDTH-1:0] a11,

    input  logic signed [IN_WIDTH-1:0] b00,
    input  logic signed [IN_WIDTH-1:0] b01,
    input  logic signed [IN_WIDTH-1:0] b10,
    input  logic signed [IN_WIDTH-1:0] b11,

    output logic valid_out,
    input  logic ready_out,

    output logic signed [ACC_WIDTH-1:0] c00,
    output logic signed [ACC_WIDTH-1:0] c01,
    output logic signed [ACC_WIDTH-1:0] c10,
    output logic signed [ACC_WIDTH-1:0] c11,

    output logic busy
);

    typedef enum logic [1:0] {
        A_IDLE,
        A_BUSY,
        A_OUT
    } accel_state_t;

    accel_state_t state;

    logic core_start;
    logic core_busy;
    logic core_done;

    logic signed [IN_WIDTH-1:0] a00_r, a01_r, a10_r, a11_r;
    logic signed [IN_WIDTH-1:0] b00_r, b01_r, b10_r, b11_r;

    logic signed [ACC_WIDTH-1:0] core_c00;
    logic signed [ACC_WIDTH-1:0] core_c01;
    logic signed [ACC_WIDTH-1:0] core_c10;
    logic signed [ACC_WIDTH-1:0] core_c11;

    logic signed [ACC_WIDTH-1:0] c00_r;
    logic signed [ACC_WIDTH-1:0] c01_r;
    logic signed [ACC_WIDTH-1:0] c10_r;
    logic signed [ACC_WIDTH-1:0] c11_r;

    assign ready_in  = (state == A_IDLE);
    assign valid_out = (state == A_OUT);
    assign busy      = (state != A_IDLE);

    assign c00 = c00_r;
    assign c01 = c01_r;
    assign c10 = c10_r;
    assign c11 = c11_r;

    matrix_mult_2x2 #(
        .IN_WIDTH(IN_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) core (
        .clk(clk),
        .rst_n(rst_n),

        .start(core_start),

        .a00(a00_r),
        .a01(a01_r),
        .a10(a10_r),
        .a11(a11_r),

        .b00(b00_r),
        .b01(b01_r),
        .b10(b10_r),
        .b11(b11_r),

        .busy(core_busy),
        .done(core_done),

        .c00(core_c00),
        .c01(core_c01),
        .c10(core_c10),
        .c11(core_c11)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= A_IDLE;

            core_start <= 1'b0;

            a00_r <= '0;
            a01_r <= '0;
            a10_r <= '0;
            a11_r <= '0;

            b00_r <= '0;
            b01_r <= '0;
            b10_r <= '0;
            b11_r <= '0;

            c00_r <= '0;
            c01_r <= '0;
            c10_r <= '0;
            c11_r <= '0;
        end else begin
            core_start <= 1'b0;

            case (state)
                A_IDLE: begin
                    if (valid_in && ready_in) begin
                        a00_r <= a00;
                        a01_r <= a01;
                        a10_r <= a10;
                        a11_r <= a11;

                        b00_r <= b00;
                        b01_r <= b01;
                        b10_r <= b10;
                        b11_r <= b11;

                        core_start <= 1'b1;
                        state <= A_BUSY;
                    end
                end

                A_BUSY: begin
                    if (core_done) begin
                        c00_r <= core_c00;
                        c01_r <= core_c01;
                        c10_r <= core_c10;
                        c11_r <= core_c11;

                        state <= A_OUT;
                    end
                end

                A_OUT: begin
                    if (ready_out) begin
                        state <= A_IDLE;
                    end
                end

                default: begin
                    state <= A_IDLE;
                end
            endcase
        end
    end

endmodule