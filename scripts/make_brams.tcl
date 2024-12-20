for {set i 0} {$i < 4} {incr i} {
    set ip_name "fram_gen_$i"
    startgroup
	create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 $ip_name
	endgroup
    set_property -dict [list \
	  CONFIG.Memory_Type {True_Dual_Port_RAM} \
	  CONFIG.Use_RSTA_Pin {true} \
	  CONFIG.Write_Depth_A {32768} \
	  CONFIG.use_bram_block {Stand_Alone} \
	  CONFIG.Enable_32bit_Address.VALUE_SRC USER \
	  CONFIG.Enable_32bit_Address {false} \
	] [get_bd_cells $ip_name]
}
