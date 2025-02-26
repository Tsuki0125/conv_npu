`include "defines.sv"
/*
module cu (
    // BRAM ports
    input [`DATA_RANGE] kernel_data  [`PE_NUM-1:0],
    input [`DATA_RANGE] feature_data,
    // decoder ports
    input [`DATA_RANGE] valid_pe_num,
    input [`PE_NUM-1:0] in_valid  ,
    input [`PE_NUM-1:0] out_en    ,
    input [`PE_NUM-1:0] calc_bias ,
    input [`PE_NUM-1:0] calc_relu ,
    input               flush     ,
    input [`FRAM_ADDR_RANGE] wb_baseaddr,
    input [`DATA_RANGE]      wb_ch_offset,
    output logic wb_busy,
    input last_uop,
    // output ports
    output logic [`DATA_RANGE] result_out,
    output logic [`FRAM_ADDR_RANGE] wb_addr,
    output logic result_out_valid,
    output logic illegal_uop,
    output logic compute_done,
    //////////////////////
    input wire clk,
    input wire rst_n
);
*/

module cu_sim ();
    reg clk;
    reg rst_n;
    // BRAM ports
    reg signed [`DATA_RANGE] kernel_data  [`PE_NUM-1:0];
    reg signed [`DATA_RANGE] feature_data;
    // decoder ports
    reg [`DATA_RANGE] valid_pe_num;
    reg [`PE_NUM-1:0] in_valid  ; 
    reg   [`PE_NUM-1:0] out_en    ;  
    reg   [`PE_NUM-1:0] calc_bias ;
    reg   [`PE_NUM-1:0] calc_relu ;
    reg                flush     ;
    reg [`FRAM_ADDR_RANGE] wb_baseaddr;
    reg [`DATA_RANGE]      wb_ch_offset;
    reg last_uop;
    // output ports
    wire signed [`DATA_RANGE] result_out;
    wire [`FRAM_ADDR_RANGE] wb_addr;
    wire result_out_valid;
    wire illegal_uop;
    wire wb_busy;
    wire compute_done;


initial begin
    clk = '0;
    rst_n = '0;
    flush = '0;
    valid_pe_num = 27;
    wb_baseaddr = 0;
    wb_ch_offset = 100;
    last_uop = '1;
    feature_data = '0;
    for (int i = 0; i < `PE_NUM; i++) begin
        in_valid[i] = '0;
        out_en[i] = '0;
        calc_bias[i] = '0;
        calc_relu[i] = '0;
        kernel_data[i] = '0;
    end
    #20 rst_n = '1;
    #20;

    normal_conv_with_relu(10);    

end

always begin
    #5 clk = ~clk;
end


task automatic normal_conv_with_relu(input int num_mac);
    for (int i = 0; i < `PE_NUM; i++) begin
        kernel_data[i] = i;
    end
    feature_data = 1;
    for ( int i=0; i<=num_mac+1; i++) begin
        @(negedge clk); //wait for clk negedge
        if (i==num_mac+1) begin
            flush = '1;
        end
        if (i==num_mac) begin
            in_valid = '0;
            calc_bias = '0;
            calc_relu = '1;
            out_en = '1;
        end
        // else if (i==num_mac) begin
        //     in_valid = '1;
        //     calc_bias = '1;
        // end
        else begin
            in_valid = '1;
        end
    end
endtask //automatic


cu DUT(.*);
endmodule