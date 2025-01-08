`include "defines.sv"

// compute unit: pe
module pe (
    input [`DATA_RANGE] x,
    input [`DATA_RANGE] weight,
    input in_valid,
    input flush,
    input out_en,
    input calc_bias,
    input calc_relu,
    //////////////////
    output wire [`DATA_RANGE] result_out,
    output reg out_valid_r,
    output reg illegal_uop,
    //////////////////
    input clk,
    input rst_n
);
wire signed [`DATA_RANGE] x_signed;
wire signed [`DATA_RANGE] weight_signed;
reg signed [`DATA_RANGE] result_nxt, result_r_signed;
reg out_valid;
assign x_signed = x;
assign weight_signed = weight;
assign result_out = result_r_signed;

// #############################################
always @* begin
    result_nxt = '0;
    out_valid = '0;
    illegal_uop = '0;
    casez ({flush, in_valid, calc_bias, calc_relu, out_en})
        5'b1????: begin
            result_nxt = '0;
            out_valid = '0; 
        end 
        5'b00000: begin
            result_nxt = result_r_signed;
            out_valid = out_valid_r;
        end 
        5'b00001: begin
            result_nxt = result_r_signed;
            out_valid = '1;
        end
        5'b00010: begin
            result_nxt = result_r_signed[`XLEN-1] ? '0 : result_r_signed;
            out_valid = '0;
        end
        5'b00011: begin
            result_nxt = result_r_signed[`XLEN-1] ? '0 : result_r_signed;
            out_valid = '1;
        end
        5'b001??, 5'b01?1?: begin
            // when calc bias, input valid must be 1
            // when calc relu, input valid must be 0
            // Cannot calc bias and relu at the same cycle
            illegal_uop = '1;
        end
        5'b01000: begin
            result_nxt = result_r_signed + x_signed * weight_signed;
        end
        5'b01001: begin
            result_nxt = result_r_signed + x_signed * weight_signed;
            out_valid = '1;
        end
        5'b01100: begin
            result_nxt = result_r_signed + weight_signed;
        end
        5'b01101: begin
            result_nxt = result_r_signed + weight_signed;
            out_valid = '1;
        end
    endcase
end



// #############################################
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        result_r_signed <= '0;
    end
    else begin
        result_r_signed <= result_nxt;
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