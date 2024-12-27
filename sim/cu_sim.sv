`include "defines.sv"

module cu_sim ();
    reg clk;
    reg rst_n;

    reg   flush;  
    reg   [`PE_NUM-1:0] in_valid  ;  
    reg   [`PE_NUM-1:0] out_en    ;  
    reg   [`PE_NUM-1:0] calc_bias ;
    reg   [`PE_NUM-1:0] calc_relu ;
    reg   signed [`DATA_RANGE] kernel_data  [`PE_NUM-1:0];
    reg   signed [`DATA_RANGE] feature_data [`PE_NUM-1:0];

    wire signed [`DATA_RANGE] result_out;
    wire result_out_valid;
    wire illegal_uop;
    wire wb_busy;

initial begin
    clk = '0;
    rst_n = '0;
    flush = '0;
    for (int i = 0; i < `PE_NUM; i++) begin
        in_valid[i] = '0;
        out_en[i] = '0;
        calc_bias[i] = '0;
        calc_relu[i] = '0;
        kernel_data[i] = '0;
        feature_data[i] = '0;
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
        kernel_data[i] = 1;
        feature_data[i] = i;
    end
    for ( int i=0; i<=num_mac+2; i++) begin
        @(negedge clk); //wait for clk negedge
        if (i==num_mac+2) begin
            flush = '1;
        end
        if (i==num_mac+1) begin
            in_valid = '0;
            calc_bias = '0;
            calc_relu = '1;
            out_en = '1;
        end
        else if (i==num_mac) begin
            in_valid = '1;
            calc_bias = '1;
        end
        else begin
            in_valid = '1;
        end
    end
endtask //automatic


cu DUT(.*);
endmodule