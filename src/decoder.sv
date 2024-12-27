`include "defines.sv"

/*module cu (
    // pe input ports
    input signed [`DATA_RANGE] kernel_data  [`PE_NUM-1:0],
    input signed [`DATA_RANGE] feature_data [`PE_NUM-1:0],
    input [`PE_NUM-1:0] in_valid  ,
    input [`PE_NUM-1:0] out_en    ,
    input [`PE_NUM-1:0] calc_bias ,
    input [`PE_NUM-1:0] calc_relu ,
    input flush,
    // output ports
    output logic signed [`DATA_RANGE] result_out,
    output logic result_out_valid,
    output logic illegal_uop,
    output logic wb_busy,
    //////////////////////
    input wire clk,
    input wire rst_n
);*/

module decoder (
    // instgen port
    // 单次卷积运算的参数
    // cu uop port
    output signed [`DATA_RANGE] kernel_data  [`PE_NUM-1:0],
    output signed [`DATA_RANGE] feature_data [`PE_NUM-1:0],
    output [`PE_NUM-1:0] in_valid  ,
    output [`PE_NUM-1:0] out_en    ,
    output [`PE_NUM-1:0] calc_bias ,
    output [`PE_NUM-1:0] calc_relu ,
    output flush,
    // BRAM port
    output logic [`FRAM_ADDR_RANGE] fram_addr,
    output logic [`KRAM_ADDR_RANGE] kram_addr,
    //////////////////////
    input wire clk,
    input wire rst_n
);


    
endmodule