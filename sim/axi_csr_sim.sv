`include "defines.sv"
/*
module axi_csr #
	(
		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= `DATA_WIDTH,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= `CSR_ADDR_WIDTH
	)
	(
		//-----------------------------------------------------------------------------------------------
		output wire [7:0] kernel_size, 	
		output wire [7:0] stride, 		
		output wire [7:0] padding, 	
		output wire has_bias,
		output wire has_relu,
		output wire conv_mode,
		output wire start,
		output wire [`DATA_RANGE] kernel_baseaddr,
		output wire [`DATA_RANGE] feature_baseaddr,
		output wire [`DATA_RANGE] feature_width,
		output wire [`DATA_RANGE] feature_height,
		output wire [`DATA_RANGE] feature_chin,
		output wire [`DATA_RANGE] feature_chout,
		output wire [`DATA_RANGE] output_baseaddr,
		output wire [`DATA_RANGE] output_width,
		output wire [`DATA_RANGE] output_height,
		//###############################################################################################
		input wire running,
		input wire compute_done,
		input wire exception,
		//-----------------------------------------------------------------------------------------------
		input wire  S_AXI_ACLK,
		input wire  S_AXI_ARESETN,
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		input wire [2 : 0] S_AXI_AWPROT,
		input wire  S_AXI_AWVALID,
		output wire  S_AXI_AWREADY,
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		input wire  S_AXI_WVALID,
		output wire  S_AXI_WREADY,
		output wire [1 : 0] S_AXI_BRESP,
		output wire  S_AXI_BVALID,
		input wire  S_AXI_BREADY,
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		input wire [2 : 0] S_AXI_ARPROT,
		input wire  S_AXI_ARVALID,
		output wire  S_AXI_ARREADY,
		output reg [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		output wire [1 : 0] S_AXI_RRESP,
		output wire  S_AXI_RVALID,
		input wire  S_AXI_RREADY
	);

*/
module axi_csr_sim;
parameter integer C_S_AXI_DATA_WIDTH	= `DATA_WIDTH;
parameter integer C_S_AXI_ADDR_WIDTH	= `CSR_ADDR_WIDTH;
//-----------------------------------------------------------------------------------------------
wire [7:0] kernel_size;
wire [7:0] stride;
wire [7:0] padding;
wire has_bias;
wire has_relu;
wire conv_mode;
wire start;
wire [`DATA_RANGE] kernel_baseaddr;
wire [`DATA_RANGE] feature_baseaddr;
wire [`DATA_RANGE] feature_width;
wire [`DATA_RANGE] feature_height;
wire [`DATA_RANGE] feature_chin;
wire [`DATA_RANGE] feature_chout;
wire [`DATA_RANGE] output_baseaddr;
wire [`DATA_RANGE] output_width;
wire [`DATA_RANGE] output_height;

wire  S_AXI_AWREADY;
wire  S_AXI_WREADY;
wire [1 : 0] S_AXI_BRESP;
wire  S_AXI_BVALID;
wire  S_AXI_ARREADY;
wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA;
wire [1 : 0] S_AXI_RRESP;
wire  S_AXI_RVALID;
//###############################################
reg running;
reg compute_done;
reg exception;
reg [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR;
reg [2 : 0] S_AXI_AWPROT;
reg  S_AXI_AWVALID;
reg [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA;
reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB;
reg  S_AXI_WVALID;
reg  S_AXI_BREADY;
reg [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR;
reg [2 : 0] S_AXI_ARPROT;
reg  S_AXI_ARVALID;
reg  S_AXI_RREADY;
reg clk;
reg rst_n;
//################################################
// Clock generation
initial begin
clk = '0;
forever #5 clk = ~clk;
end

// Reset generation
initial begin
rst_n = '1;
#20 rst_n = '0;
#20 rst_n = '1;
end

// DUT instantiation
axi_csr dut (
    .S_AXI_ACLK (clk),
    .S_AXI_ARESETN (rst_n),
    .*);

initial begin
// Initialize signals
running             = '0;
compute_done        = '0;
exception           = '0;
S_AXI_AWADDR        = '0;
S_AXI_AWPROT        = '0;
S_AXI_AWVALID       = '0;
S_AXI_WDATA         = '0;
S_AXI_WSTRB         = '0;
S_AXI_WVALID        = '0;
S_AXI_BREADY        = '1;
S_AXI_ARADDR        = '0;
S_AXI_ARPROT        = '0;
S_AXI_ARVALID       = '0;
S_AXI_RREADY        = '1;
//######################
#200;
normal_write(32'h40000000, 32'hFFFFFFFF);
normal_write(32'h40000004, 32'hFFFFFFFF);
normal_write(32'h40000008, 32'hFFFFFFFF);
normal_write(32'h4000000C, 32'hFFFFFFFF);
normal_write(32'h40000010, 32'hFFFFFFFF);
normal_write(32'h40000014, 32'hFFFFFFFF);
normal_write(32'h40000018, 32'hFFFFFFFF);
normal_write(32'h4000001C, 32'hFFFFFFFF);
normal_write(32'h40000020, 32'hFFFFFFFF);
normal_write(32'h40000024, 32'hFFFFFFFF);
#500;
normal_read(32'h40000000);
normal_read(32'h40000004);
normal_read(32'h40000008);
normal_read(32'h4000000C);
normal_read(32'h40000010);
normal_read(32'h40000014);
normal_read(32'h40000018);
normal_read(32'h4000001C);
normal_read(32'h40000020);
normal_read(32'h40000024);
end

//#############################################################

task automatic normal_write(input int addr, input int data);
    @(posedge clk);
    #1;
    S_AXI_AWVALID = '1;
    S_AXI_AWADDR = addr;
    wait(S_AXI_AWVALID && S_AXI_AWREADY);
    @(posedge clk);
    #1;
    S_AXI_AWVALID = '0;
    S_AXI_WVALID = '1;
    S_AXI_WSTRB = '1;
    S_AXI_WDATA = data;
    wait(S_AXI_WVALID && S_AXI_WREADY);
    @(posedge clk);
    #1;
    S_AXI_WVALID = '0;
    #100;
endtask 

task automatic normal_read(input int addr);
    @(posedge clk);
    #1;
    S_AXI_ARVALID = '1;
    S_AXI_ARADDR = addr;
    wait(S_AXI_ARVALID && S_AXI_ARREADY);
    @(posedge clk);
    #1;
    S_AXI_ARVALID = '0;
    wait(S_AXI_RVALID && S_AXI_RREADY);
    @(posedge clk);
    $display("value[%h] = %h", addr, S_AXI_RDATA);
    #100;
endtask 

endmodule
