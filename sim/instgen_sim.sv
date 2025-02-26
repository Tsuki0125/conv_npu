`include "defines.sv"
/*
module instgen (
    // csr port
    input [`ADDR_RANGE] feature_baseaddr,
    input [`ADDR_RANGE] kernel_baseaddr,
    input [`DATA_RANGE] feature_width,
    input [`DATA_RANGE] feature_height,
    input [`DATA_RANGE] feature_chin,
    input [`DATA_RANGE] feature_chout,
    input [7:0] kernel_sizeh,
    input [7:0] kernel_sizew,
    input has_bias,
    input has_relu,
    input [7:0] stride,
    input [`ADDR_RANGE] output_baseaddr,
    input [`DATA_RANGE] output_width,
    input [`DATA_RANGE] output_height,
    input csrcmd_valid,
    output instgen_ready,
    // decoder port
    output reg [`FRAM_ADDR_RANGE]   stride_feature_baseaddr,
    output reg [`KRAM_ADDR_RANGE]   stride_kernel_baseaddr,
    output reg [`DATA_RANGE]        stride_feature_chin,
    output reg [`DATA_RANGE]        stride_feature_chout,
    output reg [`DATA_RANGE]        stride_feature_width,
    output reg [`DATA_RANGE]        stride_feature_height,
    output reg [7:0]                stride_kernel_sizeh,
    output reg [7:0]                stride_kernel_sizew,
    output reg                      stride_has_bias,
    output reg                      stride_has_relu,
    output reg [`FRAM_ADDR_RANGE]   stride_wb_baseaddr,
    output reg [`DATA_RANGE]        stride_wb_ch_offset,
    output inst_valid,
    output reg tlast,
    input  decoder_ready,
    //////////////////////
    input wire clk,
    input wire rst_n
);
*/
module instgen_tb;

    // Parameters
    parameter ADDR_WIDTH = `ADDR_WIDTH;
    parameter DATA_WIDTH = `XLEN;

    // Signals
    reg clk;
    reg rst_n;
    reg [ADDR_WIDTH-1:0] feature_baseaddr;
    reg [ADDR_WIDTH-1:0] kernel_baseaddr;
    reg [DATA_WIDTH-1:0] feature_width;
    reg [DATA_WIDTH-1:0] feature_height;
    reg [DATA_WIDTH-1:0] feature_chin;
    reg [DATA_WIDTH-1:0] feature_chout;
    reg [7:0] kernel_sizeh;
    reg [7:0] kernel_sizew;
    reg has_bias;
    reg has_relu;
    reg [7:0] stride;
    reg [ADDR_WIDTH-1:0] output_baseaddr;
    reg [DATA_WIDTH-1:0] output_width;
    reg [DATA_WIDTH-1:0] output_height;
    reg csrcmd_valid;
    wire instgen_ready;
    // Outputs
    wire [`FRAM_ADDR_RANGE] stride_feature_baseaddr;
    wire [`KRAM_ADDR_RANGE] stride_kernel_baseaddr;
    wire [DATA_WIDTH-1:0] stride_feature_chin;
    wire [DATA_WIDTH-1:0] stride_feature_chout;
    wire [DATA_WIDTH-1:0] stride_feature_width;
    wire [DATA_WIDTH-1:0] stride_feature_height;
    wire [7:0] stride_kernel_sizeh;
    wire [7:0] stride_kernel_sizew;
    wire stride_has_bias;
    wire stride_has_relu;
    wire [`FRAM_ADDR_RANGE] stride_wb_baseaddr;
    wire [DATA_WIDTH-1:0] stride_wb_ch_offset;
    wire inst_valid;
    wire tlast;
    reg decoder_ready;

    // Instantiate the DUT (Device Under Test)
    instgen dut (.*);

    // Clock generation
    always #5 clk = ~clk;

    // Testbench sequence
    initial begin
        // Initialize signals
        clk = 0;
        rst_n = 0;
        feature_baseaddr = 32'h00000000;
        kernel_baseaddr = 32'h00000000;
        feature_width = 32'd20;
        feature_height = 32'd10;
        feature_chin = 32'd3;
        feature_chout = 32'd32;
        kernel_sizeh = 3;
        kernel_sizew = 3;
        has_bias = 1;
        has_relu = 1;
        stride = 1;
        output_baseaddr = `FRAM_ADDR_WIDTH'h00010000;
        output_width = 32'd18;
        output_height = 32'd8;
        csrcmd_valid = 0;
        decoder_ready = 0;

        // Reset the DUT
        #10 rst_n = 1;

        // Apply test vectors
        #10 csrcmd_valid = 1;
        #10 csrcmd_valid = 0;

        repeat (144) begin
            decoder_ready = 1;
            #100;
        end

        // Finish the simulation
        #600 $finish;
    end

endmodule