`include "defines.sv"

module cu (
    // BRAM ports
    input [`DATA_RANGE] kernel_data  [`PE_NUM-1:0],
    input [`DATA_RANGE] feature_data,
    // decoder ports
    input [`PE_NUM-1:0] in_valid  ,
    input [`PE_NUM-1:0] out_en    ,
    input [`PE_NUM-1:0] calc_bias ,
    input [`PE_NUM-1:0] calc_relu ,
    input               flush     ,
    input [`FRAM_ADDR_RANGE] wb_baseaddr,
    input [`DATA_RANGE]      wb_ch_offset,
    output logic wb_busy,
    // output ports
    output logic [`DATA_RANGE] result_out,
    output logic [`FRAM_ADDR_RANGE] wb_addr,
    output logic result_out_valid,
    output logic illegal_uop,
    //////////////////////
    input wire clk,
    input wire rst_n
);
    localparam IDLE = 2'b00;
    localparam OUTPUT = 2'b01; 
    reg [31:0] counter;
    reg [1:0] state;

    // input reg sync (data from brams have been synced with the primitive reg)
    reg [`PE_NUM-1:0] in_valid_sync  ;
    reg [`PE_NUM-1:0] out_en_sync    ;
    reg [`PE_NUM-1:0] calc_bias_sync ;
    reg [`PE_NUM-1:0] calc_relu_sync ;
    reg               flush_sync     ;
    reg [`FRAM_ADDR_RANGE]  wb_baseaddr_sync;
    reg [`DATA_RANGE]       wb_ch_offset_sync;
    // output reg
    reg [`DATA_RANGE] result_r [`PE_NUM-1:0];
    reg [`FRAM_ADDR_RANGE]   wb_addr_r;
    //local wires
    wire [`DATA_RANGE] pe_result [`PE_NUM-1:0];
    wire [`PE_NUM-1:0]  pe_out_valid   ;
    wire [`PE_NUM-1:0]  pe_illegal_uop ;

    assign illegal_uop = |pe_illegal_uop;
    assign wb_busy = state != IDLE;
    assign wb_addr = wb_addr_r;


    // sync process
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_valid_sync  <= '0;
            out_en_sync    <= '0;
            calc_bias_sync <= '0;
            calc_relu_sync <= '0;
            flush_sync     <= '0;
            wb_baseaddr_sync <= '0;
            wb_ch_offset_sync <= '0;
        end
        else begin
            in_valid_sync  <= in_valid;
            out_en_sync    <= out_en;
            calc_bias_sync <= calc_bias;
            calc_relu_sync <= calc_relu;
            flush_sync     <= flush;
            wb_baseaddr_sync <= wb_baseaddr;
            wb_ch_offset_sync <= wb_ch_offset;
        end 
    end
    ///////////////////////////////////////////////////////////////////////////
    // PE ARRAY
    genvar i;
    generate
        for (i = 0; i < `PE_NUM; i = i + 1) begin : pe_array
            pe u_pe (
                .x(feature_data),
                .weight(kernel_data[i]),
                .in_valid(in_valid_sync[i]),
                .flush(flush_sync),
                .out_en(out_en_sync[i]),
                .calc_bias(calc_bias_sync[i]),
                .calc_relu(calc_relu_sync[i]),
                .result_out(pe_result[i]),
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
                        wb_addr_r  <= wb_baseaddr_sync + wb_ch_offset_sync * counter;
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