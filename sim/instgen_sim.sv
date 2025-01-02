`include "defines.sv"

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
    reg [DATA_WIDTH-1:0] kernel_sizeh;
    reg [DATA_WIDTH-1:0] kernel_sizew;
    reg has_bias;
    reg has_relu;
    reg [DATA_WIDTH-1:0] stride;
    reg [ADDR_WIDTH-1:0] output_baseaddr;
    reg [DATA_WIDTH-1:0] output_width;
    reg [DATA_WIDTH-1:0] output_height;
    reg csrcmd_valid;
    wire instgen_ready;
    wire inst_valid;
    reg decoder_ready;
    wire conv_complete;

    // Outputs
    wire [`FRAM_ADDR_RANGE] stride_feature_baseaddr;
    wire [`KRAM_ADDR_RANGE] stride_kernel_baseaddr;
    wire [DATA_WIDTH-1:0] stride_feature_chin;
    wire [DATA_WIDTH-1:0] stride_feature_chout;
    wire [DATA_WIDTH-1:0] stride_feature_width;
    wire [DATA_WIDTH-1:0] stride_feature_height;
    wire [DATA_WIDTH-1:0] stride_kernel_sizeh;
    wire [DATA_WIDTH-1:0] stride_kernel_sizew;
    wire stride_has_bias;
    wire stride_has_relu;
    wire [`FRAM_ADDR_RANGE] stride_wb_baseaddr;
    wire [DATA_WIDTH-1:0] stride_wb_ch_offset;

    // Instantiate the DUT (Device Under Test)
    instgen dut (
        .clk(clk),
        .rst_n(rst_n),
        .feature_baseaddr(feature_baseaddr),
        .kernel_baseaddr(kernel_baseaddr),
        .feature_width(feature_width),
        .feature_height(feature_height),
        .feature_chin(feature_chin),
        .feature_chout(feature_chout),
        .kernel_sizeh(kernel_sizeh),
        .kernel_sizew(kernel_sizew),
        .has_bias(has_bias),
        .has_relu(has_relu),
        .stride(stride),
        .output_baseaddr(output_baseaddr),
        .output_width(output_width),
        .output_height(output_height),
        .csrcmd_valid(csrcmd_valid),
        .instgen_ready(instgen_ready),
        .inst_valid(inst_valid),
        .decoder_ready(decoder_ready),
        .conv_complete(conv_complete),
        .stride_feature_baseaddr(stride_feature_baseaddr),
        .stride_kernel_baseaddr(stride_kernel_baseaddr),
        .stride_feature_chin(stride_feature_chin),
        .stride_feature_chout(stride_feature_chout),
        .stride_feature_width(stride_feature_width),
        .stride_feature_height(stride_feature_height),
        .stride_kernel_sizeh(stride_kernel_sizeh),
        .stride_kernel_sizew(stride_kernel_sizew),
        .stride_has_bias(stride_has_bias),
        .stride_has_relu(stride_has_relu),
        .stride_wb_baseaddr(stride_wb_baseaddr),
        .stride_wb_ch_offset(stride_wb_ch_offset)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Testbench sequence
    initial begin
        // Initialize signals
        clk = 0;
        rst_n = 0;
        feature_baseaddr = 32'h00000000;
        kernel_baseaddr = 32'h00000000;
        feature_width = 32'd28;
        feature_height = 32'd28;
        feature_chin = 32'd3;
        feature_chout = 32'd64;
        kernel_sizeh = 32'd3;
        kernel_sizew = 32'd3;
        has_bias = 1;
        has_relu = 1;
        stride = 32'd1;
        output_baseaddr = `FRAM_ADDR_WIDTH'h00010000;
        output_width = 32'd26;
        output_height = 32'd26;
        csrcmd_valid = 0;
        decoder_ready = 0;

        // Reset the DUT
        #10 rst_n = 1;

        // Apply test vectors
        #10 csrcmd_valid = 1;
        #10 csrcmd_valid = 0;
        decoder_ready = 1;

        // Wait for the completion
        wait(conv_complete);

        // Finish the simulation
        #600 $finish;
    end

    // Monitor signals
    initial begin
        $monitor("Time: %0t, State: %0d, conv_complete: %0b", $time, dut.state, conv_complete);
    end

endmodule