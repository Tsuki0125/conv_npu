`include "defines.sv"

// compute unit: pe
module pe (
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
);

reg signed [`DATA_RANGE] result;
reg out_valid;
// #############################################
always @* begin
    result = '0;
    out_valid = '0;
    illegal_uop = '0;
    casez ({flush, in_valid, calc_bias, out_en})
        4'b1???: begin
            result = '0;
            out_valid = '0; 
        end 
        4'b0000: begin
            result = result_r;
            out_valid = out_valid_r;
        end 
        4'b0001: begin
            result = result_r;
            out_valid = '1;
        end
        4'b001?: begin
            illegal_uop = '1;
        end
        4'b0100: begin
            result = result_r + x * weight;
        end
        4'b0101: begin
            result = result_r + x * weight;
            out_valid = '1;
        end
        4'b0110: begin
            result = result_r + weight;
        end
        4'b0111: begin
            result = result_r + weight;
            out_valid = '1;
        end
    endcase
end



// #############################################
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        result_r <= '0;
    end
    else begin
        result_r <= result;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_valid_r <= '0;
    end
    else begin
        out_valid_r <= out_valid;
    end
end

    
endmodule