for {set i 0} {$i < 68} {incr i} {
    set ip_name "axi_bram_ctrl_$i"
    startgroup
    create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 $ip_name
    endgroup
    set_property CONFIG.SINGLE_PORT_BRAM {1} [get_bd_cells $ip_name]
}

for {set i 0} {$i < 68} {incr i} {
    set ip_name "blk_mem_gen_$i"
    startgroup
	create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 $ip_name
	endgroup
    set_property -dict [list \
	  CONFIG.Assume_Synchronous_Clk {true} \
	  CONFIG.Memory_Type {True_Dual_Port_RAM} \
	] [get_bd_cells $ip_name]
}