// general defines
`timescale 1ps/1ps

`define XLEN 32
`define DATA_RANGE 31:0
`define ADDR_WIDTH 32
`define ADDR_RANGE 31:0
// CSR addr width
`define CSR_ADDR_WIDTH 6
// pe config
`define PE_NUM 32

// BRAM MEMORY-MAP  F:FEATURE K:KERNEL
// BRAM DATA WIDTH 32: 
// feature BRAM address (NOT soc memory mapping address)
// 2bit for bank number, 13bit for address in bank
`define FRAM_ADDR_WIDTH 15
`define FRAM_ADDR_RANGE 14:0
`define FRAM_BANK_NUM 4
`define FRAM_BANKADDR_WIDTH 13
// BRAM DATA WIDTH 32: 
// kernel BRAM address (NOT soc memory mapping address)
// 6bit for bank number, 10bit for address in bank
`define KRAM_ADDR_WIDTH 16
`define KRAM_ADDR_RANGE 15:0
`define KRAM_BANK_NUM 64
`define KRAM_BANKADDR_WIDTH 10




