//#############################################################
//# Module Name: accelerator
//# Description: top of the design
//# Additional Comments:
//# .* in module instantiation means auto-connection of the same name ports 
//#############################################################

`include "defines.sv"

module accelerator #
	(
		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= `DATA_WIDTH,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= `CSR_ADDR_WIDTH,
		// Width of Byte-indexed SRAM ADDR
		parameter integer BYTE_ADDR_WIDTH_FRAM = `FRAM_ADDR_WIDTH + 2,
		parameter integer BYTE_ADDR_WIDTH_KRAM = `KRAM_ADDR_WIDTH + 2
	) (
    // AXI4-CSR Interface s00_axi
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
	// BRAM ctrl PORT (feature sram)
	input [BYTE_ADDR_WIDTH_FRAM-1 : 0] fram_addr_byteidx,
	input [`DATA_RANGE] fram_wdata,
	input fram_we,
	input fram_en,
	output [`DATA_RANGE] fram_rdata,
	// BRAM ctrl PORT (kernel sram)
	input [BYTE_ADDR_WIDTH_KRAM-1 : 0] kram_addr_byteidx,
	input [`DATA_RANGE] kram_wdata,
	input kram_we,
	input kram_en,
	output [`DATA_RANGE] kram_rdata,
	// OUTPUT:interupt - compute done
	output wire compute_done,
	//////////////////////////////////////////////////////
	input clk,
	input rst_n 
);

// bank conflict
wire bank_conflict;

//## SOC ADDR(byte indexed)  <>  BRAM Native ADDR
wire [`FRAM_ADDR_RANGE] fram_addr = fram_addr_byteidx[2 +: `FRAM_ADDR_WIDTH];
wire [`KRAM_ADDR_RANGE] kram_addr = kram_addr_byteidx[2 +: `KRAM_ADDR_WIDTH];

//################# CSR PORT  #################
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
wire [7:0] padding; // Reserved for future use
wire has_bias;
wire has_relu;
wire conv_mode;  // 0 for conv1d; 1 for conv2d
wire start;
wire running = ~instgen_ready;
wire exception = illegal_uop | bank_conflict;
//#################  feature BRAM PORTA  #################
wire [`FRAM_BANKADDR_RANGE] frambank_addr0 [`FRAM_BANK_NUM-1:0];
wire [`DATA_WIDTH-1:0] frambank_wdata0 [`FRAM_BANK_NUM-1:0];
wire [`FRAM_BANK_NUM-1:0] frambank_we0;
wire [`FRAM_BANK_NUM-1:0] frambank_en0;
wire [`DATA_WIDTH-1:0] frambank_rdata0 [`FRAM_BANK_NUM-1:0];
//#################  feature BRAM PORTB  #################
wire [`FRAM_BANKADDR_RANGE] frambank_addr1 [`FRAM_BANK_NUM-1:0];
wire [`DATA_WIDTH-1:0] frambank_wdata1 [`FRAM_BANK_NUM-1:0];
wire [`FRAM_BANK_NUM-1:0] frambank_we1;
wire [`FRAM_BANK_NUM-1:0] frambank_en1;
wire [`DATA_WIDTH-1:0] frambank_rdata1 [`FRAM_BANK_NUM-1:0];
//#################  kernel BRAM PORTA  #################
wire [`KRAM_BANKADDR_RANGE] krambank_addr0 [`KRAM_BANK_NUM-1:0];
wire [`DATA_WIDTH-1:0] krambank_wdata0 [`KRAM_BANK_NUM-1:0];
wire [`KRAM_BANK_NUM-1:0] krambank_we0;
wire [`KRAM_BANK_NUM-1:0] krambank_en0;
wire [`DATA_WIDTH-1:0] krambank_rdata0 [`KRAM_BANK_NUM-1:0];
//#################  kernel BRAM PORTB  #################
wire [`KRAM_BANKADDR_RANGE] krambank_addr1 [`KRAM_BANK_NUM-1:0];
wire [`DATA_WIDTH-1:0] krambank_wdata1 [`KRAM_BANK_NUM-1:0];
wire [`KRAM_BANK_NUM-1:0] krambank_we1;
wire [`KRAM_BANK_NUM-1:0] krambank_en1;
wire [`DATA_WIDTH-1:0] krambank_rdata1 [`KRAM_BANK_NUM-1:0];
//#################  instgen   #################
wire [7:0] kernel_sizeh = conv_mode ? kernel_size : 1;
wire [7:0] kernel_sizew = kernel_size;
wire csrcmd_valid = start;
wire instgen_ready;
wire [`FRAM_ADDR_RANGE]   stride_feature_baseaddr;
wire [`KRAM_ADDR_RANGE]   stride_kernel_baseaddr;
wire [`DATA_RANGE]        stride_feature_chin;
wire [`DATA_RANGE]        stride_feature_chout;
wire [`DATA_RANGE]        stride_feature_width;
wire [`DATA_RANGE]        stride_feature_height;
wire [7:0]        		  stride_kernel_sizeh;
wire [7:0]        	  	  stride_kernel_sizew;
wire                      stride_has_bias;
wire                      stride_has_relu;
wire inst_valid;
wire decoder_ready;
wire [`FRAM_ADDR_RANGE]   stride_wb_baseaddr;
wire [`DATA_RANGE]        stride_wb_ch_offset;
//#################  decoder  ###################
wire  [`PE_NUM-1:0] in_valid  ;
wire  [`PE_NUM-1:0] out_en    ;
wire  [`PE_NUM-1:0] calc_bias ;
wire  [`PE_NUM-1:0] calc_relu ;
wire                flush     ;
wire  [`FRAM_ADDR_RANGE] cu_wb_baseaddr;
wire  [`DATA_RANGE]      cu_wb_ch_offset;
wire wb_busy;
//################  decoder: shared srams port 
wire [`FRAM_ADDR_RANGE] shared_fram_addr;
wire [`KRAM_BANKADDR_RANGE] shared_kram_addr;
wire which_slot;
//###############  CU  #############
// cu.bramdata
wire signed [`DATA_RANGE] kernel_data  [`PE_NUM-1:0];
wire signed [`DATA_RANGE] feature_data;
// cu.output 
wire signed [`DATA_RANGE] result_out;
wire [`FRAM_ADDR_RANGE] wb_addr;
wire result_out_valid;
wire illegal_uop;
//##########################################################
//#################  module Instantiation  #################
axi_csr  u_axi_csr (
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
	.S_AXI_RREADY		(s00_axi_rready),
	.*
);


//#####################  bram_bank_mux for feature sram  ####################
bram_bank_mux #(
	.ADDR_WIDTH			(`FRAM_ADDR_WIDTH),
	.DATA_WIDTH			(`DATA_WIDTH),
	.BANK_NUM			(`FRAM_BANK_NUM),
	.BANK_ADDR_WIDTH	(`FRAM_BANKADDR_WIDTH)
) u_bram_bank_mux_feature_porta (
	.addr		(fram_addr)		,
	.wdata		(fram_wdata)	,
	.we			(fram_we)		,
	.en			(fram_en)		,
	.rdata		(fram_rdata)	,
	.bram_addr	(frambank_addr0),
	.bram_wdata	(frambank_wdata0),
	.bram_we	(frambank_we0),
	.bram_en	(frambank_en0),
	.bram_rdata	(frambank_rdata0)
);

//####################  bram_bank_mux for kernel sram  ###################
bram_bank_mux #(
	.ADDR_WIDTH			(`KRAM_ADDR_WIDTH),
	.DATA_WIDTH			(`DATA_WIDTH),
	.BANK_NUM			(`KRAM_BANK_NUM),
	.BANK_ADDR_WIDTH	(`KRAM_BANKADDR_WIDTH)
) u_bram_bank_mux_kernel (
	.addr		(kram_addr)		,
	.wdata		(kram_wdata)	,
	.we			(kram_we)		,
	.en			(kram_en)		,
	.rdata		(kram_rdata)	,
	.bram_addr	(krambank_addr0),
	.bram_wdata	(krambank_wdata0),
	.bram_we	(krambank_we0),
	.bram_en	(krambank_en0),
	.bram_rdata	(krambank_rdata0)
);

//##############  instgen  ##############
instgen u_instgen( 
	.*
);

//##############  decoder  ############
decoder u_decoder(
	.feature_baseaddr	(stride_feature_baseaddr),
	.kernel_baseaddr	(stride_kernel_baseaddr),
	.feature_chin		(stride_feature_chin),
	.feature_chout		(stride_feature_chout),
	.feature_width		(stride_feature_width),
	.feature_height		(stride_feature_height),
	.kernel_sizeh		(stride_kernel_sizeh),
	.kernel_sizew		(stride_kernel_sizew),
	.has_bias			(stride_has_bias),
	.has_relu			(stride_has_relu),
	.wb_baseaddr 		(stride_wb_baseaddr),
	.wb_ch_offset		(stride_wb_ch_offset),	
	.fram_addr	(shared_fram_addr),
	.kram_addr	(shared_kram_addr),
	.*
);
//#############  cu  ##############
cu  u_cu(
	.wb_baseaddr 	(cu_wb_baseaddr),
	.wb_ch_offset 	(cu_wb_ch_offset),
	.*
);


fram_router u_fram_router (
	// read port
	.rp_addr		(shared_fram_addr),
	.rp_rdata		(feature_data),
	// write port
	.wp_addr		(wb_addr),
	.wp_wdata		(result_out),
	.wp_en			(result_out_valid),
	// bram portb
	.bram_addr		(frambank_addr1),
	.bram_wdata		(frambank_wdata1),
	.bram_we		(frambank_we1),
	.bram_en 		(frambank_en1),
	.bram_rdata		(frambank_rdata1),
	.bank_conflict	(bank_conflict)
);

kram_router u_kram_router (
	// read port
	.slot_sel		(which_slot),
	.addr 			(shared_kram_addr),
	.rdata 			(kernel_data),
	// bram portb
	.bram_addr		(krambank_addr1),
	.bram_wdata		(krambank_wdata1),
	.bram_we		(krambank_we1),
	.bram_en 		(krambank_en1),
	.bram_rdata		(krambank_rdata1)
);


    
//#########  bram IP for feature  ##########
generate
	for (genvar i=0; i<`FRAM_BANK_NUM; i=i+1) begin: gen_fram
		bram_feature u_fram (
			//port A
			.addra		(frambank_addr0[i]),
			.clka		(clk),
			.dina		(frambank_wdata0[i]),
			.douta		(frambank_rdata0[i]),
			.ena		(frambank_en0[i]),
			.wea		(frambank_we0[i]),
			//port B
			.addrb		(frambank_addr1[i]),
			.clkb		(clk),
			.dinb		(frambank_wdata1[i]),
			.doutb		(frambank_rdata1[i]),
			.enb		(frambank_en1[i]),
			.web		(frambank_we1[i])
		);
	end
endgenerate


//##########  bram ip for kernel  ###########
generate
	for (genvar i=0; i<`KRAM_BANK_NUM; i=i+1) begin: gen_kram
		blk_mem_gen_kernel u_kram (
			//port A
			.addra		(krambank_addr0[i]),
			.clka		(clk),
			.dina		(krambank_wdata0[i]),
			.douta		(krambank_rdata0[i]),
			.ena		(krambank_en0[i]),
			.wea		(krambank_we0[i]),
			//port B
			.addrb		(krambank_addr1[i]),
			.clkb		(clk),
			.dinb		(krambank_wdata1[i]),
			.doutb		(krambank_rdata1[i]),
			.enb		(krambank_en1[i]),
			.web		(krambank_we1[i])
		);
	end
endgenerate




//////////////////////////////////////////////////////////////////////////
// module accelerator end
endmodule