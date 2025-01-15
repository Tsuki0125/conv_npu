`include "defines.sv"
//------------------------------------------------------------------------------
// Module Name: decoder
// Description: generate control signals for compute unit
// Additional Comments:
// ADDRs in instgen port is BRAM Native ADDR
// The output fram_addr is BRAM Native ADDR
// The output kram_addr is kernel-weight broadcast BANK-ADDR(SIMD)
//------------------------------------------------------------------------------

module decoder (
    // instgen port
    input [`FRAM_ADDR_RANGE] feature_baseaddr,
    input [`KRAM_ADDR_RANGE] kernel_baseaddr,
    input [`DATA_RANGE] feature_chin,
    input [`DATA_RANGE] feature_chout,
    input [`DATA_RANGE] feature_width,
    input [`DATA_RANGE] feature_height,
    input [7:0] kernel_sizeh,
    input [7:0] kernel_sizew,
    input has_bias,
    input has_relu,
    input [`FRAM_ADDR_RANGE] wb_baseaddr,
    input [`DATA_RANGE]      wb_ch_offset,
    input inst_valid,
    output decoder_ready,
    // CU port
    output reg [`DATA_RANGE] valid_pe_num,
    output reg [`PE_NUM-1:0] in_valid  ,
    output reg [`PE_NUM-1:0] out_en    ,
    output reg [`PE_NUM-1:0] calc_bias ,
    output reg [`PE_NUM-1:0] calc_relu ,
    output reg               flush     ,
    output [`FRAM_ADDR_RANGE] cu_wb_baseaddr,
    output [`DATA_RANGE]      cu_wb_ch_offset,
    input wb_busy,
    // BRAM port
    output logic [`FRAM_ADDR_RANGE] fram_addr,
    output logic [`KRAM_BANKADDR_RANGE] kram_addr,
    output logic which_slot,    // Ping-Pong BUFFER sel
    //////////////////////
    input wire clk,
    input wire rst_n
);

// FSM state
localparam IDLE     = 3'd0;
localparam DECODE   = 3'd1;
localparam MAC      = 3'd2;
localparam BIAS     = 3'd3;
localparam RELU     = 3'd4;
localparam OUTPUT   = 3'd5;
localparam FLUSH    = 3'd6;

// FSM state register
reg [2:0] state;
// FSM next state
reg [2:0] next_state;

// inst-decode regs
reg [`FRAM_ADDR_RANGE]  feature_baseaddr_r;
reg [`KRAM_ADDR_RANGE]  kernel_baseaddr_r;
reg [`DATA_RANGE]       feature_chin_r;
reg [`DATA_RANGE]       feature_chout_r;
reg [`DATA_RANGE]       feature_width_r;
reg [`DATA_RANGE]       feature_height_r;
reg [7:0]       kernel_sizeh_r;
reg [7:0]       kernel_sizew_r;
reg                     has_bias_r;
reg                     has_relu_r;
reg [`FRAM_ADDR_RANGE]  wb_baseaddr_r;
reg [`DATA_RANGE]       wb_ch_offset_r;
reg [`XLEN-1:0] kernel_flat_offset;
reg [`XLEN-1:0] feature_flat_offset;

// MAC counters
reg [`XLEN-1:0] ch_cnt;
reg [`XLEN-1:0] col_cnt;
reg [`XLEN-1:0] row_cnt;



//######################################################
//## INST REGs: 
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        feature_baseaddr_r  <= '0;
        kernel_baseaddr_r   <= '0;
        feature_chin_r      <= '0;
        feature_chout_r     <= '0;
        feature_width_r     <= '0;
        feature_height_r    <= '0;
        kernel_sizeh_r      <= '0;
        kernel_sizew_r      <= '0;
        has_bias_r          <= '0;
        has_relu_r          <= '0;
        wb_baseaddr_r       <= '0;
        wb_ch_offset_r      <= '0;
        kernel_flat_offset  <= '0;
        feature_flat_offset <= '0;
    end
    else if (inst_valid & decoder_ready) begin
        feature_baseaddr_r  <= feature_baseaddr;
        kernel_baseaddr_r   <= kernel_baseaddr;
        feature_chin_r      <= feature_chin;
        feature_chout_r     <= feature_chout;
        feature_width_r     <= feature_width;
        feature_height_r    <= feature_height;
        kernel_sizeh_r      <= kernel_sizeh;
        kernel_sizew_r      <= kernel_sizew;
        has_bias_r          <= has_bias;
        has_relu_r          <= has_relu;
        wb_baseaddr_r       <= wb_baseaddr;
        wb_ch_offset_r      <= wb_ch_offset;
        kernel_flat_offset  <= kernel_sizew * kernel_sizeh;
        feature_flat_offset <= feature_width * feature_height;
    end
end

//######################################################
//## CONV-MAC CNTs: 
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ch_cnt    <= '0;
        col_cnt   <= '0;
        row_cnt   <= '0;
        
    end
    else if (state == FLUSH) begin
        ch_cnt    <= '0;
        col_cnt   <= '0;
        row_cnt   <= '0;
    end
    else if (state == MAC) begin
        if (col_cnt == kernel_sizew_r - 1) begin
            col_cnt <= '0;
            if (row_cnt == kernel_sizeh_r - 1) begin
                row_cnt <= '0;
                if (ch_cnt < feature_chin_r) begin
                    ch_cnt <= ch_cnt + 1;
                end
            end
            else begin
                row_cnt <= row_cnt + 1;
            end
        end
        else begin
            col_cnt <= col_cnt + 1;
        end
    end
    //else 
    // just hold cnt's value
end



// FSM state transition
always @(*) begin
    case(state)
        IDLE: begin
            if(inst_valid & decoder_ready) begin
                next_state = DECODE;
            end
            else begin
                next_state = IDLE;
            end
        end
        DECODE: begin
            next_state = MAC;
        end
        MAC: begin
            if ( ch_cnt == feature_chin_r - 1 
                && row_cnt == kernel_sizeh_r - 1 
                && col_cnt == kernel_sizew_r - 1 ) begin
                if(has_bias) begin
                    next_state = BIAS;
                end else if(has_relu) begin
                    next_state = RELU;
                end else begin
                    next_state = OUTPUT;
                end
            end
            else begin
                next_state = MAC;
            end
        end
        BIAS: begin
            if(has_relu) begin
                next_state = RELU;
            end else begin
                next_state = OUTPUT;
            end
        end
        RELU: begin
            next_state = OUTPUT;
        end
        OUTPUT: begin
            if (wb_busy) begin
                next_state = OUTPUT;
            end
            else begin
                next_state = FLUSH;
            end
        end
        FLUSH: begin
            next_state = IDLE;
        end
        default: begin
            next_state = IDLE;
        end
    endcase
end

// FSM state register update
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

//FSM uops output
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        in_valid      <= '0;
        out_en        <= '0;
        calc_bias     <= '0;
        calc_relu     <= '0;
        flush         <= '0;   
    end
    else begin
        case (state)
            IDLE: begin
                in_valid      <= '0;
                out_en        <= '0;
                calc_bias     <= '0;
                calc_relu     <= '0;
                flush         <= '0;   
            end
            DECODE: begin
                in_valid      <= '0;
                out_en        <= '0;
                calc_bias     <= '0;
                calc_relu     <= '0;
                flush         <= '0; 
            end
            MAC: begin
                in_valid      <= '1;
                out_en        <= '0;
                calc_bias     <= '0;
                calc_relu     <= '0;
                flush         <= '0; 
            end
            BIAS: begin
                in_valid      <= '1;
                out_en        <= '0;
                calc_bias     <= '1;
                calc_relu     <= '0;
                flush         <= '0; 
            end
            RELU: begin
                in_valid      <= '0;
                out_en        <= '0;
                calc_bias     <= '0;
                calc_relu     <= '1;
                flush         <= '0; 
            end
            OUTPUT: begin
                if (!wb_busy) begin
                    in_valid      <= '0;
                    out_en        <= '1;
                    calc_bias     <= '0;
                    calc_relu     <= '0;
                    flush         <= '0; 
                end
                else begin
                    in_valid      <= '0;
                    out_en        <= '0;
                    calc_bias     <= '0;
                    calc_relu     <= '0;
                    flush         <= '0; 
                end
            end
            FLUSH: begin
                in_valid      <= '0;
                out_en        <= '0;
                calc_bias     <= '0;
                calc_relu     <= '0;
                flush         <= '1; 
            end
        endcase
    end
end

////////////////////////////////
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_pe_num <= '0;
    end
    else if (feature_chout_r < `PE_NUM) begin
        valid_pe_num <= feature_chout_r;
    end
    else begin
        valid_pe_num <= `PE_NUM;
    end
end

/// assigns
assign decoder_ready = (state == IDLE);
assign which_slot = kernel_baseaddr_r[`KRAM_ADDR_WIDTH-1];
// BRAM addr
wire [`DATA_RANGE] k_offset = ch_cnt * kernel_flat_offset + row_cnt * kernel_sizew_r + col_cnt;
wire [`DATA_RANGE] f_offset = ch_cnt * feature_flat_offset + row_cnt * feature_width_r + col_cnt;
assign fram_addr = feature_baseaddr_r + f_offset;
assign kram_addr = kernel_baseaddr_r[`KRAM_BANKADDR_RANGE] + k_offset;
assign cu_wb_baseaddr = wb_baseaddr_r;
assign cu_wb_ch_offset = wb_ch_offset_r;
    
endmodule