`include "define.sv"

module accelerator (
    // Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [`CSR_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [`XLEN-1 : 0] s00_axi_wdata,
		input wire [(`XLEN/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [`CSR_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [`XLEN-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready,
    // AXI BRAM controller SLAVE ports0: FEATURES
        input  logic [ADDR_WIDTH-1:0] s00_fram_addr,
        input  logic [DATA_WIDTH-1:0] s00_fram_wdata,
        input  logic                  s00_fram_we,
        input  logic                  s00_fram_clk,
        input  logic                  s00_fram_rst,
        input  logic                  s00_fram_en,
        output logic [DATA_WIDTH-1:0] s00_fram_rdata,
    // AXI BRAM controller SLAVE ports1: KERNELS
        input  logic [ADDR_WIDTH-1:0] s01_kram_addr,
        input  logic [DATA_WIDTH-1:0] s01_kram_wdata,
        input  logic                  s01_kram_we,
        input  logic                  s01_kram_clk,
        input  logic                  s01_kram_rst,
        input  logic                  s01_kram_en,
        output logic [DATA_WIDTH-1:0] s01_kram_rdata
);


    
endmodule