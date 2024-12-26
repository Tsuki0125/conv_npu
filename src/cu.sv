`include "defines.sv"

/*module pe (
    input signed [`DATA_RANGE] x,
    input signed [`DATA_RANGE] weight,
    input in_valid,
    input flush,
    input out_en,
    input calc_bias,
    //////////////////
    output reg signed [`DATA_RANGE] result_r,
    output reg out_valid_r,
    output reg illegal_uop,
    //////////////////
    input clk,
    input rst_n
);*/

module cu (
    //
    input signed [`DATA_RANGE] kernel_data [`PE_NUM-1:0],
    input signed [`DATA_RANGE] feature_data [`PE_NUM-1:0],
    input in_valid [`PE_NUM-1:0],
    input flush,
    input out_en [`PE_NUM-1:0],
    input calc_bias [`PE_NUM-1:0],
    //////////////////////
    input wire clk,
    input wire rst_n
);

    reg signed [`DATA_RANGE] result_r [`PE_NUM-1:0];
    reg out_valid_r [`PE_NUM-1:0];
    reg illegal_uop [`PE_NUM-1:0];

    // pe array
    genvar i;
    generate
        for (i = 0; i < `PE_NUM; i = i + 1) begin : pe_array
            pe u_pe (
                .x(kernel_data[i]),
                .weight(feature_data[i]),
                .in_valid(in_valid[i]),
                .flush(flush),
                .out_en(out_en[i]),
                .calc_bias(calc_bias[i]),
                .result_r(result_r[i]),
                .out_valid_r(out_valid_r[i]),
                .illegal_uop(illegal_uop[i]),
                .clk(clk),
                .rst_n(rst_n)
            );
        end
    endgenerate



    
endmodule