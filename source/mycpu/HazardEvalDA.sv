`include "common.svh"
`include "mycpu/control.svh"

module HazardEvalDA (
    input ctrl_branch_t branch_d,
    input ctrl_reg_val_t reg_write_val_e,reg_write_val_m,
    input i1 reg_write_en_e,reg_write_en_m,reg_write_en_w,
    input regidx_t reg_write_dst_e,reg_write_dst_m,reg_write_dst_w,
    input regidx_t regidx,
    output hazard_forward_t forward_d
);
    always_comb begin
        forward_d=HAZ_DEFAULT;
        if(regidx!=5'b0)begin
            case (branch_d)
                BR_BEQ,BR_BNE,BR_JR,BR_BGEZ,BR_BGTZ,BR_BLEZ,BR_BLTZ:begin
                    if(reg_write_en_e & (reg_write_dst_e==regidx) & (reg_write_val_e==VAL_ALU_RES))forward_d=HAZ_ALU_RES_E;
                    else if(reg_write_en_m & (reg_write_dst_m==regidx) & (reg_write_val_m==VAL_ALU_RES))forward_d=HAZ_ALU_RES_M;
                    else if(reg_write_en_w & (reg_write_dst_w==regidx))forward_d=HAZ_RES_W;
                    else begin
                        
                    end
                end 
                default: begin
                    if(reg_write_en_w & (reg_write_dst_w==regidx))forward_d=HAZ_RES_W;
                    else begin
                        
                    end
                end
            endcase
        end else begin
            
        end         
    end
endmodule