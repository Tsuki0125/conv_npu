`include "defines.sv"
//------------------------------------------------------------------------------
// Module Name: kram_router
// Description: connect BRAM-Array's PORTB with data consumers & producers in NPU
//------------------------------------------------------------------------------
module kram_router (
    // READ-ONLY for CU
    input  logic slot_sel,
    input  logic [`KRAM_ADDR_RANGE] addr,
    output logic [`DATA_RANGE] rdata [`PE_NUM-1:0],
    // BRAM BANK ports
    output logic [`KRAM_BANKADDR_RANGE] bram_addr [`KRAM_BANK_NUM-1:0],
    output logic [`DATA_RANGE] bram_wdata [`KRAM_BANK_NUM-1:0],
    output logic [`KRAM_BANK_NUM-1:0] bram_we,
    output logic [`KRAM_BANK_NUM-1:0] bram_en,
    input  logic [`DATA_RANGE] bram_rdata [`KRAM_BANK_NUM-1:0]
);

    // MUX logic
    always_comb begin
        for (int i = 0; i < `KRAM_BANK_NUM; i++) begin
            if (slot_sel == i / `PE_NUM) begin
                bram_addr[i]  = addr;
                bram_wdata[i] = '0;
                bram_we[i]    = 1'b0;
                bram_en[i]    = 1'b1;
            end
            else begin
                bram_addr[i]  = '0;
                bram_wdata[i] = '0;
                bram_we[i]    = '0;
                bram_en[i]    = '0;
            end
        end
    end  

    // simd read logic
    always_comb begin 
        if (slot_sel == 1'b0) begin
            for (int i=0; i < `PE_NUM; i++) begin
                rdata[i] = bram_rdata[i];
            end
        end
        else begin
            for (int i=0; i < `PE_NUM; i++) begin
                rdata[i] = bram_rdata[i+`PE_NUM];
            end
        end
    end
endmodule