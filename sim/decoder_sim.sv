`include "defines.sv"
/*
module decoder (
    // instgen port
    input [`FRAM_ADDR_RANGE] feature_baseaddr,
    input [`KRAM_ADDR_RANGE] kernel_baseaddr,
    input [`DATA_RANGE] feature_chin,
    input [`DATA_RANGE] feature_chout,
    input [`DATA_RANGE] feature_width,
    input [`DATA_RANGE] feature_height,
    input [7:0] kernel_sizeh,
    input [7:0] kernel_sizew,
    input has_bias,
    input has_relu,
    input [`FRAM_ADDR_RANGE] wb_baseaddr,
    input [`DATA_RANGE]      wb_ch_offset,
    input inst_valid,
    input tlast,
    output decoder_ready,
    // CU port
    output reg [`DATA_RANGE] valid_pe_num,
    output reg [`PE_NUM-1:0] in_valid  ,
    output reg [`PE_NUM-1:0] out_en    ,
    output reg [`PE_NUM-1:0] calc_bias ,
    output reg [`PE_NUM-1:0] calc_relu ,
    output reg               flush     ,
    output [`FRAM_ADDR_RANGE] cu_wb_baseaddr,
    output [`DATA_RANGE]      cu_wb_ch_offset,
    output reg last_uop,
    input wb_busy,
    // BRAM port
    output logic [`FRAM_ADDR_RANGE] fram_addr,
    output logic [`KRAM_BANKADDR_RANGE] kram_addr,
    output logic which_slot,    // Ping-Pong BUFFER sel
    //////////////////////
    input wire clk,
    input wire rst_n
);
*/


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
    reg [`DATA_RANGE] feature_height;
    reg [7:0] kernel_sizeh;
    reg [7:0] kernel_sizew;
    reg has_bias;
    reg has_relu;
    reg [`FRAM_ADDR_RANGE] wb_baseaddr;
    reg [`DATA_RANGE] wb_ch_offset;
    reg inst_valid;
    reg tlast;
    wire decoder_ready;
    reg [`DATA_RANGE] valid_pe_num;
    wire [`PE_NUM-1:0] in_valid;
    wire [`PE_NUM-1:0] out_en;
    wire [`PE_NUM-1:0] calc_bias;
    wire [`PE_NUM-1:0] calc_relu;
    wire flush;
    wire [`FRAM_ADDR_RANGE] cu_wb_baseaddr;
    wire [`DATA_RANGE] cu_wb_ch_offset;
    wire last_uop;
    reg wb_busy;
    // BRAM port
    wire [`FRAM_ADDR_RANGE] fram_addr;
    wire [`KRAM_ADDR_RANGE] kram_addr;
    wire which_slot;
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
        feature_height = '0;
        kernel_sizeh = '0;
        kernel_sizew = '0;
        has_bias = 0;
        has_relu = 0;
        wb_baseaddr = '0;
        wb_ch_offset = '0;
        inst_valid = 0;
        tlast = 0;
        valid_pe_num = '0;
        wb_busy = 0;

        // Apply test vectors
        #100;
        @(posedge clk);
        feature_baseaddr = 0;
        kernel_baseaddr = 0;
        feature_chin = 3;
        feature_chout = 32;
        feature_width = 200;
        feature_height = 100;
        kernel_sizeh = 3;
        kernel_sizew = 3;
        has_bias = 1;
        has_relu = 1;
        wb_baseaddr = 0;
        wb_ch_offset = 0;
        inst_valid = 1;
        tlast = '1;
        valid_pe_num = 1;
        wb_busy = 0;
        

        wait(decoder_ready & inst_valid);
        #1;
        @(posedge clk);
        inst_valid = 0;

// Wait for some time to observe the behavior
// Fish simulati
//stop
   end

endmodule