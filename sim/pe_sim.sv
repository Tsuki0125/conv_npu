`include "defines.sv"

module pe_sim ();
    reg clk;
    reg rst_n;
    wire signed [`DATA_RANGE] result_r;
    wire out_valid_r;
    wire illegal_uop;

    reg   in_valid;  
    reg   flush;  
    reg   out_en;  
    reg   calc_bias;
    reg   signed [`DATA_RANGE] x;
    reg   signed [`DATA_RANGE] weight;

initial begin
    clk = '0;
    rst_n = '0;
    in_valid = '0;
    flush = '0;
    out_en = '0;
    calc_bias = '0;
    #20 rst_n = '1;
    #20;

    normal_mac(32);    

end

always begin
    #5 clk = ~clk;
end


task automatic normal_mac(input int num_mac);
    x = `XLEN'd1;
    weight = `XLEN'd1;
    for ( int i=0; i<=num_mac+1; i++) begin
        @(negedge clk); //wait for clk negedge
        if (i==num_mac+1) begin
            flush = '1;
        end
        else if (i==num_mac) begin
            in_valid = '1;
            calc_bias = '1;
            out_en = '1;
        end
        else begin
            in_valid = '1;
        end
    end
endtask //automatic


/////////////////////////////////////////
// // compute unit: pe
// module pe (
//     input signed [`DATA_RANGE] x,
//     input signed [`DATA_RANGE] weight,
//     input in_valid,
//     input flush,
//     input out_en,
//     input calc_bias,
//     //////////////////
//     output reg signed [`DATA_RANGE] result_r,
//     output reg out_valid_r,
//     output reg illegal_uop,
//     //////////////////
//     input clk,
//     input rst_n
// );
pe DUT(
    .*
);
endmodule