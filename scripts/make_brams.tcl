# config blk_mem_gen for feature data 
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name bram_feature
set_property -dict [list \
  CONFIG.Assume_Synchronous_Clk {false} \
  CONFIG.Memory_Type {True_Dual_Port_RAM} \
  CONFIG.Write_Depth_A {8192} \
  CONFIG.Write_Width_A {32} \
] [get_ips bram_feature]


# config blk_mem_gen for kernel weights
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name bram_kernel
set_property -dict [list \
  CONFIG.Memory_Type {True_Dual_Port_RAM} \
  CONFIG.Write_Depth_A {1024} \
  CONFIG.Write_Width_A {32} \
] [get_ips bram_kernel]


