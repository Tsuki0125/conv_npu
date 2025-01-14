`include "defines.sv"

module accelerator_sim;
parameter integer C_S_AXI_DATA_WIDTH	= `DATA_WIDTH;
parameter integer C_S_AXI_ADDR_WIDTH	= `CSR_ADDR_WIDTH;
parameter integer BYTE_ADDR_WIDTH_FRAM = `FRAM_ADDR_WIDTH + 2;
parameter integer BYTE_ADDR_WIDTH_KRAM = `KRAM_ADDR_WIDTH + 2;
// AXI4-CSR Interface s00_axi
reg [C_S_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr;
reg [2 : 0] s00_axi_awprot;
reg  s00_axi_awvalid;
wire  s00_axi_awready;
reg [C_S_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata;
reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb;
reg  s00_axi_wvalid;
wire  s00_axi_wready;
wire [1 : 0] s00_axi_bresp;
wire  s00_axi_bvalid;
reg  s00_axi_bready;
reg [C_S_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr;
reg [2 : 0] s00_axi_arprot;
reg  s00_axi_arvalid;
wire  s00_axi_arready;
wire [C_S_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata;
wire [1 : 0] s00_axi_rresp;
wire  s00_axi_rvalid;
reg  s00_axi_rready;
// BRAM ctrl PORT (feature sram)
reg [BYTE_ADDR_WIDTH_FRAM-1 : 0] fram_addr_byteidx;
reg [`DATA_RANGE] fram_wdata;
reg fram_we;
reg fram_en;
wire [`DATA_RANGE] fram_rdata;
// BRAM ctrl PORT (kernel sram)
reg [BYTE_ADDR_WIDTH_KRAM-1 : 0] kram_addr_byteidx;
reg [`DATA_RANGE] kram_wdata;
reg kram_we;
reg kram_en;
wire [`DATA_RANGE] kram_rdata;
// OUTPUT:interupt - compute done
wire compute_done;
//////////////////////////////////////////////////////
reg clk;
reg rst_n;
accelerator DUT(.*);
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

//#########################################################
initial begin
// for VCS simulator:
// $fsdbDumpfile("./wave");
// $fsdbDumpvars;
/////////////////////
// Initialize signals
fram_addr_byteidx   = '0;
fram_wdata          = '0;
fram_we             = '0;
fram_en             = '0;
kram_addr_byteidx   = '0;
kram_wdata          = '0;
kram_we             = '0;
kram_en             = '0;
// axi-slave
s00_axi_awaddr      = '0;
s00_axi_awprot      = '0;
s00_axi_awvalid     = '0;
s00_axi_wdata       = '0;
s00_axi_wstrb       = '0;
s00_axi_wvalid      = '0;
s00_axi_bready      = '1;
s00_axi_araddr      = '0;
s00_axi_arprot      = '0;
s00_axi_arvalid     = '0;
s00_axi_rready      = '1;
//////////////////////////

#200;// write csrs
normal_write(32'h40000004, 32'h42000000);
normal_write(32'h40000008, 32'h44000000);
normal_write(32'h4000000C, 32'h00000064);
normal_write(32'h40000010, 32'h00000020);
normal_write(32'h40000014, 32'h00000003);
normal_write(32'h40000018, 32'h00000010);
normal_write(32'h4000001C, 32'h44010000);
normal_write(32'h40000020, 32'd49);
normal_write(32'h40000024, 32'd9);
#500;
normal_read(32'h40000004);
normal_read(32'h40000008);
normal_read(32'h4000000C);
normal_read(32'h40000010);
normal_read(32'h40000014);
normal_read(32'h40000018);
normal_read(32'h4000001C);
normal_read(32'h40000020);
normal_read(32'h40000024);
#500; // write cmd:
normal_write(32'h40000000, 32'h0302FFE1);
normal_read(32'h40000000);

wait(compute_done);
#100;
$finish;
end


//##########################################################
task automatic normal_write(input int addr, input int data);
    @(posedge clk);
    #1;
    s00_axi_awvalid = '1;
    s00_axi_awaddr = addr;
    wait(s00_axi_awvalid && s00_axi_awready);
    @(posedge clk);
    #1;
    s00_axi_awvalid = '0;
    s00_axi_wvalid = '1;
    s00_axi_wstrb = '1;
    s00_axi_wdata = data;
    wait(s00_axi_wvalid && s00_axi_wready);
    @(posedge clk);
    #1;
    s00_axi_wvalid = '0;
    #100;
endtask 

task automatic normal_read(input int addr);
    @(posedge clk);
    #1;
    s00_axi_arvalid = '1;
    s00_axi_araddr = addr;
    wait(s00_axi_arvalid && s00_axi_arready);
    @(posedge clk);
    #1;
    s00_axi_arvalid = '0;
    wait(s00_axi_rvalid && s00_axi_rready);
    @(posedge clk);
    $display("value[%h] = %h", addr, s00_axi_rdata);
    #100;
endtask 



endmodule // accelerator_sim