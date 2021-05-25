`include "common.svh"
`include "mycpu/instr.svh"
`include "mycpu/control.svh"
`include "mycpu/pipeline.svh"
`include "mycpu/shortcut.svh"

module MyCore (
    input logic clk, resetn,

    output ibus_req_t  ireq,
    output dbus_req_t  dreq,
    /* verilator lint_off UNUSED */
    input  ibus_resp_t iresp,
    input  dbus_resp_t dresp
    /* verilator lint_off UNUSED */
);
    
    pipeline_reg_fetch_t    pipe_f_nxt,pipe_f;

    /* verilator lint_off UNUSED */
    pipeline_reg_decode_t   pipe_d;
    /* verilator lint_off UNUSED */

    pipeline_reg_decode_t   pipe_d_nxt;

    /* verilator lint_off UNUSED */
    pipeline_reg_execute_t  pipe_e;
    /* verilator lint_off UNUSED */

    /* verilator lint_off UNOPTFLAT */
    pipeline_reg_execute_t  pipe_e_nxt;
    /* verilator lint_off UNOPTFLAT */
    
    pipeline_reg_memory_t   pipe_m;

    /* verilator lint_off UNOPTFLAT */
    pipeline_reg_memory_t   pipe_m_nxt;
    /* verilator lint_off UNOPTFLAT */
    
    /* verilator lint_off UNUSED */
    pipeline_reg_write_t    pipe_w;
    /* verilator lint_off UNUSED */

    pipeline_reg_write_t    pipe_w_nxt;

    i1 stall_f,stall_d,stall_e,stall_m;
    i1 flush_e,flush_w;
    hazard_forward_t forward_d_a,forward_d_b,forward_e_a,forward_e_b;

    // Register File
    regidx_t ra1,ra2;
    word_t wd3,rd1,rd2;
    
    RegFile RegFile_inst(
        .wa3(pipe_w.reg_write_dst),
        .we3(pipe_w.control.reg_write_en),
        .*);

    // Hazard Module
    Hazard Hazard_inst(
        .branch_d(pipe_e_nxt.control.branch),
        .reg_write_val_e(pipe_e.control.reg_write_val),
        .reg_write_val_m(pipe_m.control.reg_write_val),
        .reg_write_en_e(pipe_e.control.reg_write_en),
        .reg_write_en_m(pipe_m.control.reg_write_en),
        .reg_write_en_w(pipe_w.control.reg_write_en),
        .rs_d(pipe_e_nxt.rs),.rt_d(pipe_e_nxt.rt),
        .rs_e(pipe_e.rs),.rt_e(pipe_e.rt),
        .reg_write_dst_e(pipe_e.reg_write_dst),
        .reg_write_dst_m(pipe_m.reg_write_dst),
        .reg_write_dst_w(pipe_w.reg_write_dst),
        .*);

    // Fetch
    addr_t pc_branch;
    assign pipe_d_nxt.pc_plus4=pipe_f.pc+32'd4;
    assign pipe_d_nxt.pc=pipe_f.pc;

    // assign pipe_d_nxt.instr=32'd0;
    assign pipe_d_nxt.instr=iresp.data;

    AddressTranslator AddressTranslator_inst1(
        .vaddr(pipe_f.pc),
        .paddr(ireq.addr)
    );

    // assign inst_sram_en=1'b1;
    assign ireq.valid=resetn;

    // Decode
    opcode_t    opcode;
    imm_t       imm_d;
    long_imm_t  long_imm_d;
    funct_t     funct;
    btype_t     branch_flag;
    i1          pc_select;
    instr_t     instr;

    assign instr=pipe_d.instr;
    // assign instr=inst_sram_rdata;
    // assign instr=iresp.data;
    assign{
        opcode,
        pipe_e_nxt.rs,
        pipe_e_nxt.rt,
        pipe_e_nxt.rd,
        pipe_e_nxt.shamt,
        funct}=instr;
    assign imm_d=instr[15:0];
    assign branch_flag=instr[20:16];
    assign long_imm_d=instr[25:0];

    assign pipe_e_nxt.pc=pipe_d.pc;
    assign pipe_e_nxt.pc_plus8=pipe_d.pc_plus4+32'd4;

    ControlUnit ControlUnit_inst(.control(pipe_e_nxt.control),.*);

    always_comb begin
        pipe_e_nxt.src_a=rd1;
        case (forward_d_a)
            HAZ_ALU_RES_E:pipe_e_nxt.src_a=pipe_m_nxt.alu_result;
            HAZ_ALU_RES_M:pipe_e_nxt.src_a=pipe_m.alu_result;
            HAZ_RES_W:pipe_e_nxt.src_a=wd3;
            default: begin
                
            end
        endcase
    end

    always_comb begin
        pipe_e_nxt.src_b=rd2;
        case (forward_d_b)
            HAZ_ALU_RES_E:pipe_e_nxt.src_b=pipe_m_nxt.alu_result;
            HAZ_ALU_RES_M:pipe_e_nxt.src_b=pipe_m.alu_result;
            HAZ_RES_W:pipe_e_nxt.src_b=wd3;
            default: begin
                
            end
        endcase
    end

    always_comb begin
        ra1=5'd0;
        case (pipe_e_nxt.control.alu_src_a)
            ALU_SRC_RS:ra1=pipe_e_nxt.rs;
            default: begin
                
            end
        endcase
    end
    always_comb begin
        ra2=5'd0;
        pipe_e_nxt.imm=32'd0;
        case (pipe_e_nxt.control.alu_src_b)
            ALU_SRC_RT:begin
                ra2=pipe_e_nxt.rt;
                pipe_e_nxt.imm=`SIGN_EXTEND(imm_d,32);
            end 
            ALU_SRC_IMM_Z:pipe_e_nxt.imm=`ZERO_EXTEND(imm_d,32);
            ALU_SRC_IMM_S:begin
                ra2=pipe_e_nxt.rt;
                pipe_e_nxt.imm=`SIGN_EXTEND(imm_d,32);
            end
            ALU_SRC_IMM_H:pipe_e_nxt.imm={imm_d,16'd0};
            ALU_SRC_ZERO:pipe_e_nxt.imm=`SIGN_EXTEND(imm_d,32);
            default: begin
                
            end
        endcase
    end
    
    always_comb begin
        pc_branch=pipe_d.pc_plus4;
        case (pipe_e_nxt.control.branch)
            BR_BEQ,BR_BNE,BR_BGEZ,BR_BGTZ,BR_BLEZ,BR_BLTZ: pc_branch=pipe_d.pc_plus4+(pipe_e_nxt.imm<<2);
            BR_J:pc_branch={pipe_d.pc_plus4[31:28],long_imm_d,2'b00};
            BR_JR:pc_branch=pipe_e_nxt.src_a;
            default: begin
                
            end
        endcase
    end

    i1 sign_signal,zero_signal;

    assign sign_signal=pipe_e_nxt.src_a[31];
    assign zero_signal=(pipe_e_nxt.src_a==32'd0);

    always_comb begin
        pc_select=1'b0;
        case (pipe_e_nxt.control.branch)
            BR_BEQ,BR_BNE:pc_select=(pipe_e_nxt.control.branch==BR_BNE)^(pipe_e_nxt.src_a==pipe_e_nxt.src_b);
            BR_J,BR_JR:pc_select=1'b1;
            BR_BGEZ:pc_select=(~sign_signal);
            BR_BGTZ:pc_select=(~sign_signal)&(~zero_signal);
            BR_BLEZ:pc_select=sign_signal | zero_signal;
            BR_BLTZ:pc_select=sign_signal;
            default: begin
                
            end
        endcase
    end

    always_comb begin
        pipe_e_nxt.reg_write_dst=5'd0;
        case (pipe_e_nxt.control.reg_dst)
            REG_DST_RT:pipe_e_nxt.reg_write_dst=pipe_e_nxt.rt;
            REG_DST_RD:pipe_e_nxt.reg_write_dst=pipe_e_nxt.rd;
            REG_DST_RA:pipe_e_nxt.reg_write_dst=5'd31;
            default: begin
                
            end
        endcase
    end

    // Execute
    word_t alu_input_a,alu_input_b;

    assign pipe_m_nxt.control=pipe_e.control;
    assign pipe_m_nxt.pc_plus8=pipe_e.pc_plus8;
    assign pipe_m_nxt.reg_write_dst=pipe_e.reg_write_dst;
    assign pipe_m_nxt.pc=pipe_e.pc;
    
    always_comb begin
        alu_input_a=pipe_e.src_a;
        case (forward_e_a)
            HAZ_RES_W:alu_input_a=wd3;
            HAZ_ALU_RES_M:alu_input_a=pipe_m.alu_result;
            default: begin
                
            end
        endcase
    end

    always_comb begin
        pipe_m_nxt.mem_write_val=pipe_e.src_b;
        case (forward_e_b)
            HAZ_RES_W:pipe_m_nxt.mem_write_val=wd3;
            HAZ_ALU_RES_M:pipe_m_nxt.mem_write_val=pipe_m.alu_result;
            default: begin
                
            end
        endcase
    end

    always_comb begin
        alu_input_b=32'd0;
        case (pipe_e.control.alu_src_b)
            ALU_SRC_IMM_H,ALU_SRC_IMM_Z,ALU_SRC_IMM_S:alu_input_b=pipe_e.imm;
            ALU_SRC_RT:alu_input_b=pipe_m_nxt.mem_write_val;
            default: begin
                
            end
        endcase
    end

    // ALU
    always_comb begin
        pipe_m_nxt.alu_result=32'd0;
        case (pipe_e.control.alu_op)
            ALU_OP_PLUS:    pipe_m_nxt.alu_result=  alu_input_a + alu_input_b;
            ALU_OP_MINUS:   pipe_m_nxt.alu_result=  alu_input_a - alu_input_b;
            ALU_OP_AND:     pipe_m_nxt.alu_result=  alu_input_a & alu_input_b;
            ALU_OP_OR:      pipe_m_nxt.alu_result=  alu_input_a | alu_input_b;
            ALU_OP_NOR:     pipe_m_nxt.alu_result=~(alu_input_a | alu_input_b);
            ALU_OP_XOR:     pipe_m_nxt.alu_result=  alu_input_a ^ alu_input_b;
            ALU_OP_SLL:     pipe_m_nxt.alu_result=  alu_input_b <<  pipe_e.shamt;
            ALU_OP_SLLV:    pipe_m_nxt.alu_result=  alu_input_b <<  alu_input_a[4:0];
            ALU_OP_SRA:     pipe_m_nxt.alu_result=  signed'(alu_input_b) >>> pipe_e.shamt;
            ALU_OP_SRAV:    pipe_m_nxt.alu_result=  signed'(alu_input_b) >>> alu_input_a[4:0];
            ALU_OP_SRL:     pipe_m_nxt.alu_result=  alu_input_b >>  pipe_e.shamt;
            ALU_OP_SRLV:    pipe_m_nxt.alu_result=  alu_input_b >>  alu_input_a[4:0];
            ALU_OP_SLT:     pipe_m_nxt.alu_result=  {31'b0,signed'(alu_input_a)<signed'(alu_input_b)};
            ALU_OP_SLTU:    pipe_m_nxt.alu_result=  {31'b0,alu_input_a < alu_input_b};
            default: begin

            end
        endcase
    end

    // Memory
    assign pipe_w_nxt.control=pipe_m.control;
    assign pipe_w_nxt.pc_plus8=pipe_m.pc_plus8;
    assign pipe_w_nxt.reg_write_dst=pipe_m.reg_write_dst;
    assign pipe_w_nxt.alu_result=pipe_m.alu_result;
    assign pipe_w_nxt.pc=pipe_m.pc;

    // assign pipe_w_nxt.read_data=32'd0;
    assign pipe_w_nxt.read_data=dresp.data;

    // assign data_sram_en=(pipe_m.control.reg_write_val==VAL_MEM)|pipe_m.control.mem_write_en;
    // assign data_sram_wen={4{pipe_m.control.mem_write_en}};
    assign dreq.valid=(pipe_m.control.reg_write_val==VAL_MEM)|pipe_m.control.mem_write_en;
    // assign dreq.strobe={4{pipe_m.control.mem_write_en}};
    assign dreq.size=MSIZE4;

    always_comb begin:
        if(pipe_m.contorl.mem_write_en)begin
            case (pipe_m.control.ls_flag)
                LS_WORD:dreq.strobe=4'b1111;
                LS_HALFW:dreq.strobe=4'b11<<pipe_m.alu_result[1:0];
                LS_BTYE:dreq.strobe=4'b1<<pipe_m.alu_result[1:0];
                default: begin
                    dreq.strobe=4'b0;
                end
            endcase
        end else begin
            dreq.strobe=4'b0;
        end
    end

    AddressTranslator AddressTranslator_inst2(
        .vaddr(pipe_m.alu_result),
        .paddr(dreq.addr)
    );

    // assign data_sram_wdata=pipe_m.mem_write_val;
    assign dreq.data=pipe_m.mem_write_val;

    // Write Back
    word_t read_data,read_data_aligned;
    assign read_data=pipe_w.read_data;
    // assign read_data=data_sram_rdata;
    // assign read_data=dresp.data;

    always_comb begin
        wd3=32'd0;
        case (pipe_w.control.reg_write_val)
            VAL_ALU_RES:wd3=pipe_w.alu_result;
            // VAL_MEM:wd3=read_data;
            VAL_MEM:begin
                read_data_aligned=read_data>>{pipe_w.alu_result[1:0],3'b0};
                case (pipe_w.control.ls_flag)
                    LS_BTYE: wd3=`SIGN_EXTEND(read_data_aligned[7:0] ,32);
                    LS_BTYE_U:wd3=`ZERO_EXTEND(read_data_aligned[7:0],32);
                    LS_HALFW:wd3=`SIGN_EXTEND(read_data_aligned[15:0],32);
                    LS_HALFW_U:wd3=`ZERO_EXTEND(read_data_aligned[15:0],32);
                    LS_WORD:wd3=read_data;
                    default: begin
                        
                    end
                endcase
            end
            VAL_PC:wd3=pipe_w.pc_plus8;
            default: begin
                
            end
        endcase
    end

    assign pipe_f_nxt.pc=(pc_select)?pc_branch:pipe_d_nxt.pc_plus4;

    // Sequential Logic
    always_ff @( posedge clk ) begin
        if(~resetn)begin
            pipe_f.pc<=32'hbfc0_0000;
        end else if(~stall_f)begin
            pipe_f<=pipe_f_nxt;
        end else begin
            
        end
    end

    always_ff @( posedge clk ) begin
        if(~resetn)begin
            pipe_d.instr<=32'hxxxxxxxx;
            pipe_d.pc<=32'hxxxxxxxx;
            pipe_d.pc_plus4<=32'hxxxxxxxx;
        end else if(~stall_d)begin
            pipe_d<=pipe_d_nxt;
        end else begin
            
        end
    end

    always_ff @( posedge clk ) begin
        if((~resetn) | flush_e)begin
            pipe_e.control<={
                ALU_SRC_NONE,
                ALU_SRC_NONE,
                ALU_OP_NONE,
                BR_NONE,
                2'b00,
                VAL_NONE,
                REG_DST_NONE
            };
            pipe_e.src_a<=32'd0;
            pipe_e.src_b<=32'd0;
            pipe_e.rs<=5'd0;
            pipe_e.rt<=5'd0;
            pipe_e.rd<=5'd0;
            pipe_e.imm<=32'd0;
            pipe_e.shamt<=5'd0;
            pipe_e.reg_write_dst<=5'd0;
            pipe_e.pc_plus8<=32'hxxxxxxxx;
        end else if(~stall_e) begin
            pipe_e<=pipe_e_nxt;
        end else begin
            
        end
    end

    always_ff @( posedge clk ) begin
        if(~resetn)begin
            pipe_m.control<={
                ALU_SRC_NONE,
                ALU_SRC_NONE,
                ALU_OP_NONE,
                BR_NONE,
                2'b00,
                VAL_NONE,
                REG_DST_NONE
            };
            pipe_m.pc<=32'hxxxxxxxx;
            pipe_m.alu_result<=32'd0;
            pipe_m.mem_write_val<=32'd0;
            pipe_m.reg_write_dst<=5'd0;
            pipe_m.pc_plus8<=32'hxxxxxxxx;
        end else if(~stall_m) begin
            pipe_m<=pipe_m_nxt;
        end else begin
            
        end
    end

    always_ff @( posedge clk ) begin
        if((~resetn) | flush_w)begin
            pipe_w.control<={
                ALU_SRC_NONE,
                ALU_SRC_NONE,
                ALU_OP_NONE,
                BR_NONE,
                2'b00,
                VAL_NONE,
                REG_DST_NONE
            };
            pipe_w.pc<=32'hxxxxxxxx;
            pipe_w.read_data<=32'd0;
            pipe_w.alu_result<=32'd0;
            pipe_w.reg_write_dst<=5'd0;
            pipe_w.pc_plus8<=32'hxxxxxxxx;
        end else begin
            pipe_w<=pipe_w_nxt;
        end
    end

    // remove following lines when you start
    // assign ireq = '0;
    // assign dreq = '0;
    // `UNUSED_OK({iresp, dresp});
endmodule
