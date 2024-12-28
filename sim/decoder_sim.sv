`include "defines.sv"

module decoder_sim;

    // Parameters
    localparam CLK_PERIOD = 10;

    // Signals
    reg clk;
    reg rst_n;
    reg [`FRAM_ADDR_RANGE] feature_baseaddr;
    reg [`KRAM_ADDR_RANGE] kernel_baseaddr;
    reg [`DATA_RANGE] feature_chin;
    reg [`DATA_RANGE] feature_chout;
    reg [`DATA_RANGE] feature_width;
    reg [`DATA_RANGE] kernel_sizeh;
    reg [`DATA_RANGE] kernel_sizew;
    reg has_bias;
    reg has_relu;
    reg [`FRAM_ADDR_RANGE] output_baseaddr;
    reg inst_valid;
    wire decoder_ready;
    wire [`PE_NUM-1:0] in_valid;
    wire [`PE_NUM-1:0] out_en;
    wire [`PE_NUM-1:0] calc_bias;
    wire [`PE_NUM-1:0] calc_relu;
    wire flush;
    reg wb_busy;
    wire [`FRAM_ADDR_RANGE] fram_addr;
    wire [`KRAM_ADDR_RANGE] kram_addr;

    // Instantiate the decoder module
    decoder dut (.*);

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Reset generation
    initial begin
        rst_n = 0;
        #20;
        rst_n = 1;
    end

    // Stimulus
    initial begin
        // Initialize inputs
        feature_baseaddr = '0;
        kernel_baseaddr = '0;
        feature_chin = '0;
        feature_chout = '0;
        feature_width = '0;
        kernel_sizeh = '0;
        kernel_sizew = '0;
        has_bias = 0;
        has_relu = 0;
        output_baseaddr = '0;
        inst_valid = 0;
        wb_busy = 0;

        // Apply test vectors
        #100;
        @(posedge clk);
        feature_baseaddr = 32'h0000_0000;
        kernel_baseaddr = 32'h0000_0000;
        feature_chin = 32'h0000_0003;
        feature_chout = 32'd32;
        feature_width = 32'd256;
        kernel_sizeh = 32'd3;
        kernel_sizew = 32'd3;
        has_bias = 1;
        has_relu = 1;
        output_baseaddr = 32'h0000_0000;
        inst_valid = 1;

        wait(decoder_ready & inst_valid);
        #1;
        @(posedge clk);
        inst_valid = 0;

        // Wait for some time to observe the behavior

        // Finish simulation
        // $stop;
    end

endmodule