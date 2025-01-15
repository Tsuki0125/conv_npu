`include "defines.sv"
//------------------------------------------------------------------------------
// Module Name: instgen
// Description: generate CONV stride control signals (instructions) for decoder
// Additional Comments:
// The addresses in the csr port IS the SOC Memory-Mapping addr: 
// e.g.: [`ADDR_RANGE]
// The addresses in the decoder port IS the BRAM Native addr:
// e.g.: [`FRAM_ADDR_RANGE], [`KRAM_ADDR_RANGE]
//------------------------------------------------------------------------------

module instgen (
    // csr port
    input [`ADDR_RANGE] feature_baseaddr,
    input [`ADDR_RANGE] kernel_baseaddr,
    input [`DATA_RANGE] feature_width,
    input [`DATA_RANGE] feature_height,
    input [`DATA_RANGE] feature_chin,
    input [`DATA_RANGE] feature_chout,
    input [7:0] kernel_sizeh,
    input [7:0] kernel_sizew,
    input has_bias,
    input has_relu,
    input [7:0] stride,
    input [`ADDR_RANGE] output_baseaddr,
    input [`DATA_RANGE] output_width,
    input [`DATA_RANGE] output_height,
    input csrcmd_valid,
    output instgen_ready,
    // decoder port
    output reg [`FRAM_ADDR_RANGE]   stride_feature_baseaddr,
    output reg [`KRAM_ADDR_RANGE]   stride_kernel_baseaddr,
    output reg [`DATA_RANGE]        stride_feature_chin,
    output reg [`DATA_RANGE]        stride_feature_chout,
    output reg [`DATA_RANGE]        stride_feature_width,
    output reg [`DATA_RANGE]        stride_feature_height,
    output reg [7:0]                stride_kernel_sizeh,
    output reg [7:0]                stride_kernel_sizew,
    output reg                      stride_has_bias,
    output reg                      stride_has_relu,
    output reg [`FRAM_ADDR_RANGE]   stride_wb_baseaddr,
    output reg [`DATA_RANGE]        stride_wb_ch_offset,
    output inst_valid,
    output reg tlast,
    input  decoder_ready,
    //////////////////////
    input wire clk,
    input wire rst_n
);

// FSM state
localparam IDLE     = 3'd0;
localparam INIT     = 3'd1;
localparam EXEC     = 3'd2;
localparam DONE     = 3'd3;


// FSM state register
reg [2:0] state;
// FSM next state
reg [2:0] next_state;

// instgen regs
reg [`ADDR_RANGE]       feature_baseaddr_r;
reg [`ADDR_RANGE]       kernel_baseaddr_r;
reg [`DATA_RANGE]       feature_chin_r;
reg [`DATA_RANGE]       feature_chout_r;
reg [`DATA_RANGE]       feature_width_r;
reg [`DATA_RANGE]       feature_height_r;
reg [7:0]               kernel_sizeh_r;
reg [7:0]               kernel_sizew_r;
reg                     has_bias_r;
reg                     has_relu_r;
reg [7:0]               stride_r;
reg [`ADDR_RANGE]       wb_baseaddr_r;
reg [`DATA_RANGE]       output_width_r;
reg [`DATA_RANGE]       output_height_r;

// conv stride control signals
reg [`DATA_RANGE]       position_x, position_x_nxt;
reg [`DATA_RANGE]       position_y, position_y_nxt;
reg [`DATA_RANGE]       feature_flat_offset;
reg [`FRAM_ADDR_RANGE]  wbaddr_offset;
reg conv_done;


//###############################################################
assign instgen_ready = (state == IDLE);
assign inst_valid = (state == EXEC);

// CSR CMD sync process:
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
        stride_r            <= '0;
        wb_baseaddr_r       <= '0;
        output_width_r      <= '0;
        output_height_r     <= '0;
        feature_flat_offset <= '0;
    end
    else if (csrcmd_valid && instgen_ready) begin
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
        stride_r            <= stride;
        wb_baseaddr_r       <= output_baseaddr;
        output_width_r      <= output_width;
        output_height_r     <= output_height;
        feature_flat_offset <= feature_width * feature_height;
    end
end

// conv stride process:
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        position_x <= '0;
        position_y <= '0;
    end
    else begin
        position_x <= position_x_nxt;
        position_y <= position_y_nxt;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wbaddr_offset <= '0;
    end
    else if (state != EXEC) begin
        wbaddr_offset <= '0;
    end
    else if(inst_valid && decoder_ready) begin
        wbaddr_offset <= wbaddr_offset + 1;
    end
end

always @* begin
    position_x_nxt = '0;
    position_y_nxt = '0;
    conv_done = '0;
    casez (state)
        IDLE: begin
            position_x_nxt = '0;
            position_y_nxt = '0;
        end
        INIT: begin
            position_x_nxt = kernel_sizew_r - 1;
            position_y_nxt = kernel_sizeh_r - 1;
        end
        EXEC: begin
            if(inst_valid && decoder_ready) begin
                position_x_nxt = position_x + stride_r;
                if (position_x_nxt >= feature_width_r) begin
                    position_x_nxt = kernel_sizew_r - 1;
                    position_y_nxt = position_y + stride_r;
                    if (position_y_nxt >= feature_height_r) begin
                        conv_done = 1;
                    end
                end
                else begin
                    position_y_nxt = position_y;
                end
            end
            else begin
                position_x_nxt = position_x;
                position_y_nxt = position_y;
            end
        end
        default: begin
            position_x_nxt = '0;
            position_y_nxt = '0;
        end
    endcase
end

// FSM state transition
always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

always @* begin
    tlast = '0;
    casez (state)
        IDLE: begin
            if (csrcmd_valid & instgen_ready) begin
                next_state = INIT;
            end else begin
                next_state = IDLE;
            end
        end
        INIT: begin
            next_state = EXEC;
        end
        EXEC: begin
            if (conv_done & decoder_ready) begin
                next_state = DONE;
                tlast = '1;
            end else begin
                next_state = EXEC;
            end
        end
        DONE: begin
            if (decoder_ready) begin
                next_state = IDLE;
            end
            else begin
                next_state = DONE;
            end
        end
        default: 
            next_state = IDLE;
    endcase
end

// handy assignment:
wire [`DATA_RANGE] f_offset = (position_y - kernel_sizeh_r + 1) * feature_width_r + position_x - kernel_sizew_r + 1; 
// stride instruction gen: 
always @* begin
    stride_feature_baseaddr = feature_baseaddr_r[2+:`FRAM_ADDR_WIDTH] + f_offset;
    stride_kernel_baseaddr = kernel_baseaddr_r[2+:`KRAM_ADDR_WIDTH];
    stride_feature_chin = feature_chin_r;
    stride_feature_chout = feature_chout_r;
    stride_feature_width = feature_width_r;
    stride_feature_height = feature_height_r;
    stride_kernel_sizeh = kernel_sizeh_r;
    stride_kernel_sizew = kernel_sizew_r;
    stride_has_bias = has_bias_r;
    stride_has_relu = has_relu_r;
    stride_wb_baseaddr = wb_baseaddr_r[2+:`FRAM_ADDR_WIDTH] + wbaddr_offset;
    stride_wb_ch_offset = output_width_r * output_height_r;
end

endmodule