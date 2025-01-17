// simulation defines
`timescale 1ns/1ps

// parameters in SOC
`define XLEN 32
`define DATA_WIDTH 32
`define DATA_RANGE 31:0
`define ADDR_WIDTH 32
`define ADDR_RANGE 31:0

// CSR defines
`define CSR_ADDR_WIDTH 6

// PE defines
`define PE_NUM 32


// feature BRAM defines
// DATA WIDTH 32
// 2bit for bank number, 13bit for address in bank
`define FRAM_ADDR_WIDTH 15
`define FRAM_ADDR_RANGE 14:0

`define FRAM_BANK_NUM 4
`define FRAM_BANKADDR_WIDTH 13
`define FRAM_BANKADDR_RANGE 12:0
// kernel BRAM defines
// DATA WIDTH 32
// 6bit for bank number, 10bit for address in bank
`define KRAM_ADDR_WIDTH 16
`define KRAM_ADDR_RANGE 15:0

`define KRAM_BANK_NUM 64
`define KRAM_BANKADDR_WIDTH 10
`define KRAM_BANKADDR_RANGE 9:0




