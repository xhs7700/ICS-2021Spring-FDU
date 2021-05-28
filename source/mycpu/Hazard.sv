`include "common.svh"
`include "mycpu/control.svh"

module Hazard (
    input i1 i_valid,d_valid,i_data_ok,d_data_ok,
    input ctrl_branch_t branch_d,
    input ctrl_reg_val_t reg_write_val_e,reg_write_val_m,
    input i1 reg_write_en_e,reg_write_en_m,reg_write_en_w,
    input i2 hilo_write_en_m,hilo_write_en_w,
    input regidx_t rs_d,rt_d,rs_e,rt_e,
    input regidx_t reg_write_dst_e,reg_write_dst_m,reg_write_dst_w,
    input ctrl_alu_src_t alu_src_d,alu_src_e,
    output i1 stall_f,stall_d,stall_e,stall_m,
    output i1 flush_e,flush_w,
    output hazard_forward_t forward_d_a,forward_d_b,forward_e_a,forward_e_b
);
    i1 lw_stall,iresp_stall,dresp_stall;
    // assign lw_stall=((reg_write_val_e==VAL_MEM)|(reg_write_val_m==VAL_MEM))&((rt_e==rs_d)|(rt_e==rt_d));
    
    always_comb begin
        lw_stall=1'b0;
        case (branch_d)
            BR_BEQ,BR_BNE,BR_JR:begin
                lw_stall=((reg_write_val_e==VAL_MEM)&((rt_e==rs_d)|(rt_e==rt_d)))|((reg_write_val_m==VAL_MEM)&((reg_write_dst_m==rs_d)|(reg_write_dst_m==rt_d)));
            end
            default: begin
                lw_stall=(reg_write_val_e==VAL_MEM)&((rt_e==rs_d)|(rt_e==rt_d));
            end
        endcase
    end
    
    assign iresp_stall=i_valid & (~i_data_ok);
    // assign iresp_stall=(~i_data_ok);
    assign dresp_stall=d_valid & (~d_data_ok);

    assign stall_f=lw_stall | iresp_stall | dresp_stall;
    assign stall_d=lw_stall | iresp_stall | dresp_stall;
    assign stall_e=dresp_stall;
    assign stall_m=dresp_stall;
    
    assign flush_e=lw_stall | iresp_stall;
    assign flush_w=dresp_stall;

    HazardEvalDA hazard_eval_d_a(.regidx(rs_d),.forward_d(forward_d_a),.*);
    HazardEvalDB hazard_eval_d_b(.regidx(rt_d),.forward_d(forward_d_b),.alu_src(alu_src_d),.*);

    HazardEvalE hazard_eval_e_a(.regidx(rs_e),.forward_e(forward_e_a),.alu_src(ALU_SRC_NONE),.*);
    HazardEvalE hazard_eval_e_b(.regidx(rt_e),.forward_e(forward_e_b),.alu_src(alu_src_e),.*);

endmodule