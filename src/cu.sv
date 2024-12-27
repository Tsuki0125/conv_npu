`include "defines.sv"

/*module pe (
    input signed [`DATA_RANGE] x,
    input signed [`DATA_RANGE] weight,
    input in_valid,
    input flush,
    input out_en,
    input calc_bias,
    input calc_relu,
    //////////////////
    output reg signed [`DATA_RANGE] result_r,
    output reg out_valid_r,
    output reg illegal_uop,
    //////////////////
    input clk,
    input rst_n
);*/

module cu (
    // pe input ports
    input signed [`DATA_RANGE] kernel_data [`PE_NUM-1:0],
    input signed [`DATA_RANGE] feature_data [`PE_NUM-1:0],
    input in_valid [`PE_NUM-1:0],
    input flush,
    input out_en [`PE_NUM-1:0],
    input calc_bias [`PE_NUM-1:0],
    input calc_relu [`PE_NUM-1:0],
    // output ports
    output logic signed [`DATA_RANGE] result_out,
    output logic result_out_valid,
    output logic illegal_uop,
    output logic wb_busy,
    //////////////////////
    input wire clk,
    input wire rst_n
);
    localparam IDLE = 2'b00;
    localparam OUTPUT = 2'b01; 

    wire signed [`DATA_RANGE] pe_result [`PE_NUM-1:0];
    wire pe_out_valid [`PE_NUM-1:0];
    wire pe_illegal_uop [`PE_NUM-1:0];

    reg signed [`DATA_RANGE] result_r [`PE_NUM-1:0];
    reg [31:0] counter;
    reg [1:0] state;

    assign illegal_uop = |pe_illegal_uop;
    assign wb_busy = state != IDLE;

    // PE ARRAY
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
                .calc_relu(calc_relu[i]),
                .result_r(pe_result[i]),
                .out_valid_r(pe_out_valid[i]),
                .illegal_uop(pe_illegal_uop[i]),
                .clk(clk),
                .rst_n(rst_n)
            );
        end
    endgenerate


    // WRITE BACK QUEUE
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            for (int i = 0; i < `PE_NUM; i++) begin
                result_r[i] <= '0;
            end
            counter <= 0;
            state <= IDLE;
            result_out <= '0;
            result_out_valid <= '0;
        end
        else begin
            case (state)
                IDLE: begin
                    for (int i = 0; i < `PE_NUM; i++) begin
                        if (pe_out_valid[i]) begin
                            result_r[i] <= pe_result[i];
                        end
                    end
                    counter <= 0;
                    state <= OUTPUT;
                end
                OUTPUT: begin
                    if (counter < `PE_NUM) begin
                        result_out <= result_r[counter];
                        result_out_valid <= 1;
                        counter <= counter + 1;
                    end
                    else begin
                        result_out <= '0;
                        result_out_valid <= 0;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end


endmodule