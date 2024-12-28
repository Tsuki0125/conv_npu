`include "defines.sv"

module decoder (
    // instgen port
    input [`FRAM_ADDR_RANGE] feature_baseaddr,
    input [`KRAM_ADDR_RANGE] kernel_baseaddr,
    input [`DATA_RANGE] feature_chin,
    input [`DATA_RANGE] feature_chout,
    input [`DATA_RANGE] feature_width,
    input [`DATA_RANGE] kernel_sizeh,
    input [`DATA_RANGE] kernel_sizew,
    input has_bias,
    input has_relu,
    input [`FRAM_ADDR_RANGE] output_baseaddr,
    input inst_valid,
    output reg decoder_ready,
    // cu port
    // output reg signed [`DATA_RANGE] kernel_data  [`PE_NUM-1:0],
    // output reg signed [`DATA_RANGE] feature_data [`PE_NUM-1:0],
    output reg [`PE_NUM-1:0] in_valid  ,
    output reg [`PE_NUM-1:0] out_en    ,
    output reg [`PE_NUM-1:0] calc_bias ,
    output reg [`PE_NUM-1:0] calc_relu ,
    output reg               flush     ,
    input wb_busy,
    // BRAM port
    output logic [`FRAM_ADDR_RANGE] fram_addr,
    output logic [`KRAM_ADDR_RANGE] kram_addr,
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
reg [`DATA_RANGE]       kernel_sizeh_r;
reg [`DATA_RANGE]       kernel_sizew_r;
reg                     has_bias_r;
reg                     has_relu_r;
reg [`FRAM_ADDR_RANGE]  output_baseaddr_r;

// MAC counters
reg [`XLEN-1:0] ch_cnt;
reg [`XLEN-1:0] col_cnt;
reg [`XLEN-1:0] row_cnt;
reg [`XLEN-1:0] flat_offset;


//######################################################
//## INST REGs: 
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        feature_baseaddr_r  <= '0;
        kernel_baseaddr_r   <= '0;
        feature_chin_r      <= '0;
        feature_chout_r     <= '0;
        feature_width_r     <= '0;
        kernel_sizeh_r      <= '0;
        kernel_sizew_r      <= '0;
        has_bias_r          <= '0;
        has_relu_r          <= '0;
        output_baseaddr_r   <= '0;
    end
    else if (inst_valid & decoder_ready) begin
        feature_baseaddr_r  <= feature_baseaddr;
        kernel_baseaddr_r   <= kernel_baseaddr;
        feature_chin_r      <= feature_chin;
        feature_chout_r     <= feature_chout;
        feature_width_r     <= feature_width;
        kernel_sizeh_r      <= kernel_sizeh;
        kernel_sizew_r      <= kernel_sizew;
        has_bias_r          <= has_bias;
        has_relu_r          <= has_relu;
        output_baseaddr_r   <= output_baseaddr;
    end
end

//######################################################
//## CONV-MAC CNTs: 
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ch_cnt    <= '0;
        col_cnt   <= '0;
        row_cnt   <= '0;
        flat_offset <= '0;
    end
    else if (state == FLUSH) begin
        ch_cnt    <= '0;
        col_cnt   <= '0;
        row_cnt   <= '0;
        flat_offset <= '0;
    end
    else if (state == DECODE) begin
        flat_offset <= kernel_sizew_r * feature_chin_r;
    end
    else if (state == MAC) begin
        if (ch_cnt == feature_chin_r - 1) begin
            ch_cnt <= '0;
            if (col_cnt == kernel_sizew_r - 1) begin
                col_cnt <= '0;
                if (row_cnt < kernel_sizeh_r) begin
                    row_cnt <= row_cnt + 1;
                end
            end
            else begin
                col_cnt <= col_cnt + 1;
            end
        end
        else begin
            ch_cnt <= ch_cnt + 1;
        end
    end
    //else 
    // just hold cnts' value
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
            if (row_cnt == kernel_sizeh_r) begin
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

//FSM outputs
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        decoder_ready <= '0;
        in_valid      <= '0;
        out_en        <= '0;
        calc_bias     <= '0;
        calc_relu     <= '0;
        flush         <= '0;    
    end
    else begin
        case (state)
            IDLE: begin
                decoder_ready <= '1;
                in_valid      <= '0;
                out_en        <= '0;
                calc_bias     <= '0;
                calc_relu     <= '0;
                flush         <= '0;   
            end
            DECODE: begin
                decoder_ready <= '0;
                in_valid      <= '0;
                out_en        <= '0;
                calc_bias     <= '0;
                calc_relu     <= '0;
                flush         <= '0; 
            end
            MAC: begin
                decoder_ready <= '0;
                in_valid      <= '1;
                out_en        <= '0;
                calc_bias     <= '0;
                calc_relu     <= '0;
                flush         <= '0; 
            end
            BIAS: begin
                decoder_ready <= '0;
                in_valid      <= '1;
                out_en        <= '0;
                calc_bias     <= '1;
                calc_relu     <= '0;
                flush         <= '0; 
            end
            RELU: begin
                decoder_ready <= '0;
                in_valid      <= '0;
                out_en        <= '0;
                calc_bias     <= '0;
                calc_relu     <= '1;
                flush         <= '0; 
            end
            OUTPUT: begin
                if (!wb_busy) begin
                    decoder_ready <= '0;
                    in_valid      <= '0;
                    out_en        <= '1;
                    calc_bias     <= '0;
                    calc_relu     <= '0;
                    flush         <= '0; 
                end
                else begin
                    decoder_ready <= '0;
                    in_valid      <= '0;
                    out_en        <= '0;
                    calc_bias     <= '0;
                    calc_relu     <= '0;
                    flush         <= '0; 
                end
            end
            FLUSH: begin
                decoder_ready <= '0;
                in_valid      <= '0;
                out_en        <= '0;
                calc_bias     <= '0;
                calc_relu     <= '0;
                flush         <= '1; 
            end
        endcase
    end
end

// BRAM addr
wire [`XLEN-1:0] offset = row_cnt * flat_offset + col_cnt * feature_chin_r + ch_cnt;
assign fram_addr = feature_baseaddr_r + offset;
assign kram_addr = kernel_baseaddr_r + offset;

    
endmodule