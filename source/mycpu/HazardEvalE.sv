`include "common.svh"
`include "mycpu/control.svh"

module HazardEvalE (
    input ctrl_reg_val_t reg_write_val_m,
    input i1 reg_write_en_m,reg_write_en_w,
    input regidx_t reg_write_dst_m,reg_write_dst_w,
    input regidx_t regidx,
    output hazard_forward_t forward_e
);
    always_comb begin
        forward_e=HAZ_DEFAULT;
        if(regidx!=5'b0)begin
            if(reg_write_en_m & (reg_write_dst_m==regidx) & (reg_write_val_m==VAL_ALU_RES))forward_e=HAZ_ALU_RES_M;
            else if(reg_write_en_w & (reg_write_dst_w==regidx))forward_e=HAZ_RES_W;
            else begin
                
            end
        end else begin
            
        end
    end
endmodule