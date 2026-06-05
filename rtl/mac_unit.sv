module mac_unit #(
    parameter int IN_WIDTH  = 8,
    parameter int ACC_WIDTH = 32
)(
    input  logic clk,
    input  logic rst_n,

    input  logic clear,
    input  logic enable,

    input  logic signed [IN_WIDTH-1:0] a,
    input  logic signed [IN_WIDTH-1:0] b,

    output logic signed [ACC_WIDTH-1:0] acc
);

    localparam int PRODUCT_WIDTH = 2 * IN_WIDTH;

    logic signed [PRODUCT_WIDTH-1:0] product;
    logic signed [ACC_WIDTH-1:0] product_ext;

    assign product = a * b;

    assign product_ext = {{(ACC_WIDTH-PRODUCT_WIDTH){product[PRODUCT_WIDTH-1]}}, product};

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc <= '0;
        end else if (clear) begin
            acc <= '0;
        end else if (enable) begin
            acc <= acc + product_ext;
        end
    end

endmodule