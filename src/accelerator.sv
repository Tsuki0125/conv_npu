`include "defines.sv"

module accelerator #
	(
		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= `XLEN,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= `CSR_ADDR_WIDTH
	) (
    // Ports of Axi Slave Bus Interface S00_AXI - AXI4-CSR
	input wire  s00_axi_aclk,
	input wire  s00_axi_aresetn,
	input wire [C_S_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
	input wire [2 : 0] s00_axi_awprot,
	input wire  s00_axi_awvalid,
	output wire  s00_axi_awready,
	input wire [C_S_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
	input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
	input wire  s00_axi_wvalid,
	output wire  s00_axi_wready,
	output wire [1 : 0] s00_axi_bresp,
	output wire  s00_axi_bvalid,
	input wire  s00_axi_bready,
	input wire [C_S_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
	input wire [2 : 0] s00_axi_arprot,
	input wire  s00_axi_arvalid,
	output wire  s00_axi_arready,
	output wire [C_S_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
	output wire [1 : 0] s00_axi_rresp,
	output wire  s00_axi_rvalid,
	input wire  s00_axi_rready,
	// AXI-Slave - bram ctrl(feature sram)
	//TODO
	// AXI-Slave - bram ctrl(kernel sram)

	// interupt signal: compute done

	//////////////////////////////////////////////////////
	input clk,
	input rst_n 
);


wire [`DATA_RANGE] kernel_baseaddr;
wire [`DATA_RANGE] feature_baseaddr;
wire [`DATA_RANGE] feature_width;
wire [`DATA_RANGE] feature_height;
wire [`DATA_RANGE] feature_chin;
wire [`DATA_RANGE] feature_chout;
wire [`DATA_RANGE] output_baseaddr;
wire [`DATA_RANGE] output_width;
wire [`DATA_RANGE] output_height;
wire [7:0] kernel_size;
wire [7:0] stride;
wire [7:0] padding;
wire has_bias;
wire has_relu;
wire conv_mode;
wire start;
wire running = 1'b0;
wire conv_done	= 1'b0;
wire exception	= 1'b0;


//----------------------------------------------------------
//#################  module Instantiation  #################
// Instantiation of Axi Bus Interface S_AXI
axi_csr  u_axi_csr (
	// csr register
	.kernel_size		(kernel_size)		,
	.stride				(stride)			,
	.padding			(padding)			,
	.has_bias			(has_bias)			,
	.has_relu			(has_relu)			,
	.conv_mode			(conv_mode)			,
	.running			(running)			,
	.conv_done			(conv_done)			,
	.exception			(exception)			,
	.start				(start)				,
	.kernel_baseaddr	(kernel_baseaddr)	,
	.feature_baseaddr	(feature_baseaddr)	,
	.feature_width		(feature_width)		,
	.feature_height		(feature_height)	,
	.feature_chin		(feature_chin)		,
	.feature_chout		(feature_chout)		,
	.output_baseaddr	(output_baseaddr)	,
	.output_width		(output_width)		,
	.output_height		(output_height)		,
	// axi slave bus interface
	.S_AXI_ACLK			(s00_axi_aclk),
	.S_AXI_ARESETN		(s00_axi_aresetn),
	.S_AXI_AWADDR		(s00_axi_awaddr),
	.S_AXI_AWPROT		(s00_axi_awprot),
	.S_AXI_AWVALID		(s00_axi_awvalid),
	.S_AXI_AWREADY		(s00_axi_awready),
	.S_AXI_WDATA		(s00_axi_wdata),
	.S_AXI_WSTRB		(s00_axi_wstrb),
	.S_AXI_WVALID		(s00_axi_wvalid),
	.S_AXI_WREADY		(s00_axi_wready),
	.S_AXI_BRESP		(s00_axi_bresp),
	.S_AXI_BVALID		(s00_axi_bvalid),
	.S_AXI_BREADY		(s00_axi_bready),
	.S_AXI_ARADDR		(s00_axi_araddr),
	.S_AXI_ARPROT		(s00_axi_arprot),
	.S_AXI_ARVALID		(s00_axi_arvalid),
	.S_AXI_ARREADY		(s00_axi_arready),
	.S_AXI_RDATA		(s00_axi_rdata),
	.S_AXI_RRESP		(s00_axi_rresp),
	.S_AXI_RVALID		(s00_axi_rvalid),
	.S_AXI_RREADY		(s00_axi_rready)
);

    
endmodule