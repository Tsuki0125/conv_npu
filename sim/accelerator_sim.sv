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
//##############################################################
//##############     vars for testbench code    ################
//##############################################################
int feature_in_array[$]; 
int feature_in_linenum;//9600 = 3*32*100
int weights_array[$];
int weights_linenum;//27 = 1*3*3*3
int feature_out_array[$];
int feature_out_linenum;//735 = 15*49
int test_fram_base = 0;
int test_kram_base = 0;
int test_output_base = 16384;
int tb_rdata;
//##############################################################
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
// 调用task读取文件内容
read_file("feature_in.txt", feature_in_array, feature_in_linenum);
read_file("feature_out.txt", feature_out_array, feature_out_linenum);
read_file("weights.txt", weights_array, weights_linenum);

// 打印读文件取到的数据，观察是否读取正常
for (int i = 0; i < feature_in_linenum; i++) begin
    $display("Feature In Data[%0d] = %0d", i, feature_in_array[i]);
end
for (int i = 0; i < feature_out_linenum; i++) begin
    $display("Feature Out Data[%0d] = %0d", i, feature_out_array[i]);
end
for (int i = 0; i < weights_linenum; i++) begin
    $display("Weights Data[%0d] = %0d", i, weights_array[i]);
end

// 将输入数据通过BRAM端口写入
#200; // wait for rst
for (int i = 0; i < feature_in_linenum; i++) begin
    fram_write((test_fram_base+i)<<2,  feature_in_array[i] );
end
fram_writerst;
for (int i = 0; i < weights_linenum; i++) begin
    kram_write((test_kram_base+i)<<2,  weights_array[i] );
end
kram_writerst;
// 读出上述地址，验证BRAM测试数据写入完成
#500;
for (int i = 0; i < feature_in_linenum; i++) begin
    fram_read((test_fram_base+i)<<2, tb_rdata);
    if (tb_rdata != feature_in_array[i]) begin
        $display("feature_in data[%d] error!", i);
        $finish;
    end
end
for (int i = 0; i < weights_linenum; i++) begin
    kram_read((test_kram_base+i)<<2, tb_rdata);
    if (tb_rdata != weights_array[i]) begin
        $display("weights data[%d] error!", i);
        $finish;
    end
end
// 写控制状态寄存器，发送计算命令
#200;
axi_lite_write(32'h40000004, 32'h42000000);
axi_lite_write(32'h40000008, 32'h44000000);
axi_lite_write(32'h4000000C, 32'h00000064);
axi_lite_write(32'h40000010, 32'h00000020);
axi_lite_write(32'h40000014, 32'h00000003);
axi_lite_write(32'h40000018, 32'h00000001);
axi_lite_write(32'h4000001C, 32'h44010000);
axi_lite_write(32'h40000020, 32'd49);
axi_lite_write(32'h40000024, 32'd15);
#500;
axi_lite_read(32'h40000004);
axi_lite_read(32'h40000008);
axi_lite_read(32'h4000000C);
axi_lite_read(32'h40000010);
axi_lite_read(32'h40000014);
axi_lite_read(32'h40000018);
axi_lite_read(32'h4000001C);
axi_lite_read(32'h40000020);
axi_lite_read(32'h40000024);
#500; // write cmd:
axi_lite_write(32'h40000000, 32'h0302FF21);
axi_lite_read(32'h40000000);

wait(compute_done);
#200;

// 读出计算结果
for (int i = 0; i < feature_out_linenum; i++) begin
    fram_read((test_output_base+i)<<2, tb_rdata);
    if (tb_rdata != feature_out_array[i]) begin
        $display("conv output result data[%d] error!", i);
        $finish;
    end
end

///////////////////////////////////
#100;
$display("#############################################");
$display("##########    CONV TEST PASSED!    ##########");
$display("#############################################");
$finish;
end


//##########################################################
task automatic axi_lite_write(input int addr, input int data);
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

task automatic axi_lite_read(input int addr);
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

//////////////////////////////////////////////////////
task automatic fram_write(input int addr, input int data);
    @(posedge clk);
    #1;
    fram_addr_byteidx   = addr;
    fram_wdata          = data;
    fram_we             = '1;
    fram_en             = '1;
endtask
task automatic fram_writerst;
    @(posedge clk);
    #1;
    fram_addr_byteidx   = '0;
    fram_wdata          = '0;
    fram_we             = '0;
    fram_en             = '0;
endtask
task automatic kram_write(input int addr, input int data);
    @(posedge clk);
    #1;
    kram_addr_byteidx   = addr;
    kram_wdata          = data;
    kram_we             = '1;
    kram_en             = '1;
endtask
task automatic kram_writerst;
    @(posedge clk);
    #1;
    kram_addr_byteidx   = '0;
    kram_wdata          = '0;
    kram_we             = '0;
    kram_en             = '0;
endtask
//////////////////////////////////////////////////////
task automatic kram_read(input int addr, output int rdata);
    @(posedge clk);
    #1;
    kram_addr_byteidx   = addr;
    kram_we             = '0;
    kram_en             = '1;
    @(posedge clk);
    #1;
    kram_addr_byteidx   = '0;
    kram_we             = '0;
    kram_en             = '0;
    $display("value of kram[%h] = %h", addr, kram_rdata);
    rdata = kram_rdata;
endtask 

task automatic fram_read(input int addr, output int rdata);
    @(posedge clk);
    #1;
    fram_addr_byteidx   = addr;
    fram_we             = '0;
    fram_en             = '1;
    @(posedge clk);
    #1;
    fram_addr_byteidx   = '0;
    fram_we             = '0;
    fram_en             = '0;
    $display("value of fram[%h] = %h", addr, fram_rdata);
    rdata = fram_rdata;
endtask 
//////////////////////////////////////////////////////
task automatic read_file(input string filename, ref int data_array[$], output int num_lines);
    int file, r;
    logic signed [31:0] data;
    string line;

    begin
        // 初始化行数
        num_lines = 0;
        // 打开文件
        file = $fopen(filename, "r");
        if (file == 0) begin
            $display("Error: Could not open file %s.", filename);
            $finish;
        end

        // 逐行读取文件内容
        while (!$feof(file)) begin
            // 读取一行
            r = $fgets(line, file);
            if (r != 0) begin
                // 将二进制字符串转换为有符号整数
                r = $sscanf(line, "%b", data);
                $display("############################");
                $display("original line   is %s", line);
                $display("the parsed data is %d", data);
                if (r == 1) begin
                    // 成功读取到一个整数，存储到数组中
                    data_array[num_lines] = data;
                    num_lines++;
                    $display("sizeof data array is %d", $size(data_array));
                end else begin
                    $display("Error: Could not parse line: %s", line);
                    $display("parser's return code is %d", r);
                end
            end
        end
        // 关闭文件
        $fclose(file);
    end
endtask
/////////////////////////////////////////////////////////////
endmodule // accelerator_sim