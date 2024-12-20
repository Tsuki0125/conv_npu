module bram_bank_mux #(
    parameter ADDR_WIDTH = 17,
    parameter DATA_WIDTH = 32,
    parameter BANK_NUM = 4,
    parameter BANK_ADDR_WIDTH = ADDR_WIDTH - $clog2(BANK_NUM)
)(
    // AXI BRAM controller SLAVE ports
    input  logic [ADDR_WIDTH-1:0] addr,
    input  logic [DATA_WIDTH-1:0] wdata,
    input  logic                  we,
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  en,
    output logic [DATA_WIDTH-1:0] rdata,
    // BRAM BANK ports
    output logic [BANK_ADDR_WIDTH-1:0] bram_addr [BANK_NUM-1:0],
    output logic [DATA_WIDTH-1:0] bram_wdata [BANK_NUM-1:0],
    output logic [BANK_NUM-1:0] bram_we,
    output logic [BANK_NUM-1:0] bram_clk,
    output logic [BANK_NUM-1:0] bram_rst,
    output logic [BANK_NUM-1:0] bram_en,
    input  logic [DATA_WIDTH-1:0] bram_rdata [BANK_NUM-1:0]
);
    // handle clk and reset
    always_comb begin
        for (int i = 0; i < BANK_NUM; i++) begin
            bram_clk[i] = clk;
            bram_rst[i] = rst;
        end
    end

    // Address high bits to select the bank
    logic [$clog2(BANK_NUM)-1:0] bank_sel;
    assign bank_sel = addr[ADDR_WIDTH-1:ADDR_WIDTH-$clog2(BANK_NUM)];

    // MUX logic
    always_comb begin
        for (int i = 0; i < BANK_NUM; i++) begin
            bram_addr[i]  = addr;
            bram_wdata[i] = wdata;
            bram_we[i]    = (bank_sel == i) ? we : 1'b0;
            bram_en[i]    = (bank_sel == i) ? en : 1'b0;
        end
        rdata = bram_rdata[bank_sel];
    end

endmodule