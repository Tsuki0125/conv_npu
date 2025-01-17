`include "defines.sv"
//------------------------------------------------------------------------------
// Module Name: fram_router
// Description: connect BRAM-Array's PORTB with data consumers & producers in NPU
//------------------------------------------------------------------------------

module fram_router (
    // read port
    input  logic [`FRAM_ADDR_RANGE] rp_addr,
    output logic [`DATA_RANGE] rp_rdata,
    // write port
    input  logic [`FRAM_ADDR_RANGE] wp_addr,
    input  logic [`DATA_RANGE] wp_wdata,
    input  logic                  wp_en,
    // BRAM BANK ports
    output logic [`FRAM_BANKADDR_RANGE]  bram_addr [`FRAM_BANK_NUM-1:0],
    output logic [`DATA_RANGE]       bram_wdata [`FRAM_BANK_NUM-1:0],
    output logic [`FRAM_BANK_NUM-1:0]         bram_we,
    output logic [`FRAM_BANK_NUM-1:0]         bram_en,
    input  logic [`DATA_RANGE]       bram_rdata [`FRAM_BANK_NUM-1:0],
    // addr bank conflict
    output wire bank_conflict,
    input clk,
    input rst_n
);

    // High bits to select the bank
    logic [$clog2(`FRAM_BANK_NUM)-1:0] bank_sel_rp, bank_sel_wp;
    reg   [$clog2(`FRAM_BANK_NUM)-1:0] bank_sel_rp_delay; // BRAM's dout delay 1-clk After Read-signals
    assign bank_sel_rp = rp_addr[`FRAM_ADDR_WIDTH-1:`FRAM_ADDR_WIDTH-$clog2(`FRAM_BANK_NUM)];
    assign bank_sel_wp = wp_addr[`FRAM_ADDR_WIDTH-1:`FRAM_ADDR_WIDTH-$clog2(`FRAM_BANK_NUM)];
    assign bank_conflict = (bank_sel_rp == bank_sel_wp) && wp_en;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bank_sel_rp_delay <= '0;
        end
        else begin
            bank_sel_rp_delay <= bank_sel_rp;
        end
    end


    // MUX logic
    always_comb begin
        for (int i = 0; i < `FRAM_BANK_NUM; i++) begin
            if ((bank_sel_wp == i) && wp_en) begin
                bram_addr[i]  = wp_addr;
                bram_wdata[i] = wp_wdata;
                bram_we[i]    = wp_en;
                bram_en[i]    = wp_en;
            end
            else if (bank_sel_rp == i) begin
                bram_addr[i]  = rp_addr;
                bram_wdata[i] = '0;
                bram_we[i]    = '0;
                bram_en[i]    = 1'b1;
            end
            else begin
                bram_addr[i]  = '0;
                bram_wdata[i] = '0;
                bram_we[i]    = '0;
                bram_en[i]    = '0;
            end
        end
        rp_rdata = bram_rdata[bank_sel_rp_delay];
    end
    
endmodule



