`include "common.svh"
`include "mycpu/control.svh"

module HazardEvalE (
    input ctrl_reg_val_t reg_write_val_m,
    input i1 reg_write_en_m,reg_write_en_w,
    input i2 hilo_write_en_m,hilo_write_en_w,
    input regidx_t reg_write_dst_m,reg_write_dst_w,
    input regidx_t regidx,
    input ctrl_alu_src_t alu_src,
    output hazard_forward_t forward_e
);
    always_comb begin
        case (alu_src)
            ALU_SRC_HI:begin
                if(hilo_write_en_m[1])begin
                    forward_e=(hilo_write_en_m[0]?HAZ_HI_M:HAZ_ALU_RES_M);
                end else if(hilo_write_en_w[1])begin
                    forward_e=(hilo_write_en_w[0]?HAZ_HI_W:HAZ_RES_W);
                end else begin
                    forward_e=HAZ_DEFAULT;
                end
            end
            ALU_SRC_LO:begin
                if(hilo_write_en_m[0])begin
                    forward_e=(hilo_write_en_m[1]?HAZ_LO_M:HAZ_ALU_RES_M);
                end else if(hilo_write_en_w[0])begin
                    forward_e=(hilo_write_en_w[1]?HAZ_LO_W:HAZ_RES_W);
                end else begin
                    forward_e=HAZ_DEFAULT;
                end
            end
            default: begin
                forward_e=HAZ_DEFAULT;
                if(regidx!=5'b0)begin
                    if(reg_write_en_m & (reg_write_dst_m==regidx) & (reg_write_val_m==VAL_ALU_RES))forward_e=HAZ_ALU_RES_M;
                    else if(reg_write_en_w & (reg_write_dst_w==regidx))forward_e=HAZ_RES_W;
                    else begin
                        
                    end
                end else begin
                    
                end
            end
        endcase
    end
endmodule