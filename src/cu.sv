`include "defines.sv"

module cu (
    // BRAM ports
    input signed [`DATA_RANGE] kernel_data  [`PE_NUM-1:0],
    input signed [`DATA_RANGE] feature_data [`PE_NUM-1:0],
    // decoder ports
    input [`PE_NUM-1:0] in_valid  ,
    input [`PE_NUM-1:0] out_en    ,
    input [`PE_NUM-1:0] calc_bias ,
    input [`PE_NUM-1:0] calc_relu ,
    input               flush,
    input [`FRAM_ADDR_RANGE] wb_baseaddr,
    input [`DATA_RANGE] wb_ch_offset,
    output logic wb_busy,
    // output ports
    output logic signed [`DATA_RANGE] result_out,
    output logic [`FRAM_ADDR_RANGE] wb_addr,
    output logic result_out_valid,
    output logic illegal_uop,
    //////////////////////
    input wire clk,
    input wire rst_n
);
    localparam IDLE = 2'b00;
    localparam OUTPUT = 2'b01; 

    wire signed [`DATA_RANGE] pe_result [`PE_NUM-1:0];
    wire [`PE_NUM-1:0]  pe_out_valid   ;
    wire [`PE_NUM-1:0]  pe_illegal_uop ;

    reg signed [`DATA_RANGE] result_r [`PE_NUM-1:0];
    reg [`FRAM_ADDR_RANGE]   wb_addr_r;
    reg [31:0] counter;
    reg [1:0] state;

    assign illegal_uop = |pe_illegal_uop;
    assign wb_busy = state != IDLE;

    // PE ARRAY
    genvar i;
    generate
        for (i = 0; i < `PE_NUM; i = i + 1) begin : pe_array
            pe u_pe (
                .x(feature_data[i]),
                .weight(kernel_data[i]),
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
            wb_addr_r <= '0;
            wb_addr <= '0;
        end
        else begin
            case (state)
                IDLE: begin
                    wb_addr_r <= '0;
                    if (|pe_out_valid) begin
                        for (int i = 0; i < `PE_NUM; i++) begin
                            result_r[i] <= pe_result[i];
                        end
                        counter <= 0;
                        state <= OUTPUT;
                    end
                end
                OUTPUT: begin
                    if (counter < `PE_NUM) begin
                        result_out <= result_r[counter];
                        wb_addr_r  <= wb_baseaddr + wb_ch_offset * counter;
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