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
	input wire [] //TODO
	// AXI-Slave - bram ctrl(kernel sram)

	// interupt signal: compute done

	//////////////////////////////////////////////////////
	input clk,
	input rst_n 
);

// csr register
reg [`DATA_RANGE] csr_npu_control;
reg [`DATA_RANGE] csr_kernel_baseaddr;
reg [`DATA_RANGE] csr_feature_baseaddr;
reg [`DATA_RANGE] csr_feature_width;
reg [`DATA_RANGE] csr_feature_height;
reg [`DATA_RANGE] csr_feature_chin;
reg [`DATA_RANGE] csr_feature_chout;
reg [`DATA_RANGE] csr_output_baseaddr;
reg [`DATA_RANGE] csr_output_width;
reg [`DATA_RANGE] csr_output_height;
// wires from axi-csr to csr-register
wire [`DATA_RANGE] npu_control;
wire [`DATA_RANGE] kernel_baseaddr;
wire [`DATA_RANGE] feature_baseaddr;
wire [`DATA_RANGE] feature_width;
wire [`DATA_RANGE] feature_height;
wire [`DATA_RANGE] feature_chin;
wire [`DATA_RANGE] feature_chout;
wire [`DATA_RANGE] output_baseaddr;
wire [`DATA_RANGE] output_width;
wire [`DATA_RANGE] output_height;
// npu control bit select:
wire [7:0] kernel_size 	= csr_npu_control[31:24];
wire [7:0] stride 		= csr_npu_control[23:16];
wire [7:0] padding 		= csr_npu_control[15:8];
wire has_bias 			= csr_npu_control[7];
wire has_relu 			= csr_npu_control[6];
wire conv_mode 			= csr_npu_control[5];
// wire reserved 		= csr_npu_control[4];
wire running 			= csr_npu_control[3];
wire done 				= csr_npu_control[2];
wire exception 			= csr_npu_control[1];
wire start 				= csr_npu_control[0];







always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		csr_npu_control 		<= '0;
		csr_kernel_baseaddr		<= '0;
		csr_feature_baseaddr 	<= '0;
		csr_feature_width 		<= '0;
		csr_feature_height 		<= '0;
		csr_feature_chin 		<= '0;
		csr_feature_chout 		<= '0;
		csr_output_baseaddr 	<= '0;
		csr_output_width 		<= '0;
		csr_output_height 		<= '0;
	end
	else if (!running) begin // write csr register when NOT RUNNING
		csr_npu_control 		<= (npu_control & 32'hFFFF_FFF1) ; //some bits are READ-ONLY
		csr_kernel_baseaddr 	<= kernel_baseaddr;
		csr_feature_baseaddr 	<= feature_baseaddr;
		csr_feature_width 		<= feature_width;
		csr_feature_height 		<= feature_height;
		csr_feature_chin 		<= feature_chin;
		csr_feature_chout 		<= feature_chout;
		csr_output_baseaddr 	<= output_baseaddr;
		csr_output_width 		<= output_width;
		csr_output_height 		<= output_height;
	end
end






//----------------------------------------------------------
//#################  module Instantiation  #################
// Instantiation of Axi Bus Interface S_AXI
axi_csr  u_axi_csr (
	// csr register
	.npu_control		(npu_control)		,
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