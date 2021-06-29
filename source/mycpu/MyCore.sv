`include "common.svh"
`include "mycpu/instr.svh"
`include "mycpu/control.svh"
`include "mycpu/pipeline.svh"
`include "mycpu/shortcut.svh"

module MyCore (
    input logic clk, resetn,
    input i6 ext_int,

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

    cp0_reg_t cp0,cp0_nxt;

    i1 stall_f,stall_d,stall_e,stall_m;
    i1 flush_e,flush_w,flush_before_w;
    hazard_forward_t forward_d_a,forward_d_b,forward_e_a,forward_e_b;

    // Register File
    regidx_t ra1,ra2;
    regidx_t wa3 /* verilator public_flat_rd */;
    i1 we3 /* verilator public_flat_rd */;
    word_t wd3 /* verilator public_flat_rd */;
    word_t rd1,rd2;
    word_t hi,lo;
    
    assign wa3=pipe_w.reg_write_dst;
    assign we3=pipe_w.control.reg_write_en;

    RegFile RegFile_inst(.*);

    hilo hilo_inst(
        .hi_we(pipe_w.control.hilo_write_en[1]),
        .lo_we(pipe_w.control.hilo_write_en[0]),
        .hi_data(pipe_w.hi_result),
        .lo_data(pipe_w.lo_result),
        .*);

    // Hazard Module
    Hazard Hazard_inst(
        .i_valid(ireq.valid),.d_valid(dreq.valid),
        .i_data_ok(iresp.data_ok),.d_data_ok(dresp.data_ok),
        .branch_d(pipe_e_nxt.control.branch),
        .reg_write_val_e(pipe_e.control.reg_write_val),
        .reg_write_val_m(pipe_m.control.reg_write_val),
        .reg_write_en_e(pipe_e.control.reg_write_en),
        .reg_write_en_m(pipe_m.control.reg_write_en),
        .reg_write_en_w(pipe_w.control.reg_write_en),
        .hilo_write_en_m(pipe_m.control.hilo_write_en),
        .hilo_write_en_w(pipe_w.control.hilo_write_en),
        .rs_d(pipe_e_nxt.rs),.rt_d(pipe_e_nxt.rt),
        .rs_e(pipe_e.rs),.rt_e(pipe_e.rt),
        .reg_write_dst_e(pipe_e.reg_write_dst),
        .reg_write_dst_m(pipe_m.reg_write_dst),
        .reg_write_dst_w(pipe_w.reg_write_dst),
        .alu_src_d(pipe_e_nxt.control.alu_src_b),
        .alu_src_e(pipe_e.control.alu_src_b),.*);

    // Fetch
    addr_t pc_branch;
    assign pipe_d_nxt.pc_plus4=pipe_f.pc+32'd4;
    assign pipe_d_nxt.pc=pipe_f.pc;

    // assign pipe_d_nxt.instr=32'd0;
    assign pipe_d_nxt.instr=iresp.data;

    assign ireq.valid=resetn;

    always_comb begin
        ireq.addr=pipe_f.pc;
        pipe_d_nxt.exc_code='0;
        if(ireq.addr&32'd3!='0)begin
            pipe_d_nxt.exc_code.AdEI=1'b1;
            ireq.addr=ireq.addr&32'hfffffffc;
        end
    end

    // Decode
    imm_t       imm_d;
    long_imm_t  long_imm_d;
    i5          branch_flag;
    i1          pc_select;
    instr_t     instr;
    i1          ins_error;

    assign instr=pipe_d.instr;
    // assign instr=iresp.data;
    
    assign pipe_e_nxt.rs=instr[25:21];
    assign pipe_e_nxt.rt=instr[20:16];
    assign pipe_e_nxt.rd=instr[15:11];
    assign pipe_e_nxt.shamt=instr[10:6];
    assign imm_d=instr[15:0];
    assign branch_flag=instr[20:16];
    assign long_imm_d=instr[25:0];

    assign pipe_e_nxt.exc_code.RI=ins_error;
    assign pipe_e_nxt.is_cond=pipe_d.is_cond;
    assign pipe_e_nxt.pc=pipe_d.pc;
    assign pipe_e_nxt.pc_plus8=pipe_d.pc_plus4+32'd4;

    ControlUnit ControlUnit_inst(.control(pipe_e_nxt.control),.*);

    always_comb begin
        case (forward_d_a)
            HAZ_ALU_RES_E:pipe_e_nxt.src_a=pipe_m_nxt.alu_result;
            HAZ_ALU_RES_M:pipe_e_nxt.src_a=pipe_m.alu_result;
            HAZ_RES_W:pipe_e_nxt.src_a=wd3;
            default: begin
                pipe_e_nxt.src_a=rd1;
            end
        endcase
    end

    always_comb begin
        case (forward_d_b)
            HAZ_ALU_RES_E:pipe_e_nxt.src_b=pipe_m_nxt.alu_result;
            HAZ_ALU_RES_M:pipe_e_nxt.src_b=pipe_m.alu_result;
            HAZ_RES_W:pipe_e_nxt.src_b=wd3;
            HAZ_HI_W:pipe_e_nxt.src_b=pipe_w.hi_result;
            HAZ_LO_W:pipe_e_nxt.src_b=pipe_w.lo_result;
            default: begin
                case (pipe_e_nxt.control.alu_src_b)
                    ALU_SRC_HI:pipe_e_nxt.src_b=hi;
                    ALU_SRC_LO:pipe_e_nxt.src_b=lo;
                    ALU_SRC_C0:begin
                        case (pipe_e_nxt.rd)
                            5'd8:pipe_e_nxt.src_b=cp0.BadVAddr;
                            5'd9:pipe_e_nxt.src_b=cp0.Count;
                            5'd11:pipe_e_nxt.src_b=cp0.Compare;
                            5'd12:pipe_e_nxt.src_b=cp0.Status;
                            5'd13:pipe_e_nxt.src_b=cp0.Cause;
                            5'd14:pipe_e_nxt.src_b=cp0.EPC;
                            default: pipe_e_nxt.src_b='0;
                        endcase
                    end
                    default:pipe_e_nxt.src_b=rd2;
                endcase
            end
        endcase
    end

    always_comb begin
        case (pipe_e_nxt.control.alu_src_a)
            ALU_SRC_RS:ra1=pipe_e_nxt.rs;
            default: begin
                ra1=5'd0;
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
        pipe_d_nxt.is_cond=1'b0;
        case (pipe_e_nxt.control.branch)
            BR_BEQ,BR_BNE,BR_BGEZ,BR_BGTZ,BR_BLEZ,BR_BLTZ:begin
                pc_branch=pipe_d.pc_plus4+(pipe_e_nxt.imm<<2);
                pipe_d_nxt.is_cond=1'b1;
            end
            BR_J:pc_branch={pipe_d.pc_plus4[31:28],long_imm_d,2'b00};
            BR_JR:pc_branch=pipe_e_nxt.src_a;
            default: begin
                pc_branch=pipe_d.pc_plus4;
            end
        endcase
    end

    i1 sign_signal,zero_signal;

    assign sign_signal=pipe_e_nxt.src_a[31];
    assign zero_signal=(pipe_e_nxt.src_a==32'd0);

    always_comb begin
        case (pipe_e_nxt.control.branch)
            BR_BEQ,BR_BNE:pc_select=(pipe_e_nxt.control.branch==BR_BNE)^(pipe_e_nxt.src_a==pipe_e_nxt.src_b);
            BR_J,BR_JR:pc_select=1'b1;
            BR_BGEZ:pc_select=(~sign_signal);
            BR_BGTZ:pc_select=(~sign_signal)&(~zero_signal);
            BR_BLEZ:pc_select=sign_signal | zero_signal;
            BR_BLTZ:pc_select=sign_signal;
            default: begin
                pc_select=1'b0;
            end
        endcase
    end

    always_comb begin
        case (pipe_e_nxt.control.reg_dst)
            REG_DST_RT:pipe_e_nxt.reg_write_dst=pipe_e_nxt.rt;
            REG_DST_RD:pipe_e_nxt.reg_write_dst=pipe_e_nxt.rd;
            REG_DST_RA:pipe_e_nxt.reg_write_dst=5'd31;
            default: begin
                pipe_e_nxt.reg_write_dst=5'd0;
            end
        endcase
    end

    // Execute
    word_t alu_input_a,alu_input_b;

    assign pipe_m_nxt.control=pipe_e.control;
    assign pipe_m_nxt.is_cond=pipe_e.is_cond;
    assign pipe_m_nxt.pc_plus8=pipe_e.pc_plus8;
    assign pipe_m_nxt.reg_write_dst=pipe_e.reg_write_dst;
    assign pipe_m_nxt.pc=pipe_e.pc;
    
    always_comb begin
        case (forward_e_a)
            HAZ_RES_W:alu_input_a=wd3;
            HAZ_ALU_RES_M:alu_input_a=pipe_m.alu_result;
            default: begin
                alu_input_a=pipe_e.src_a;
            end
        endcase
    end

    always_comb begin
        case (forward_e_b)
            HAZ_RES_W:pipe_m_nxt.mem_write_val=wd3;
            HAZ_ALU_RES_M:pipe_m_nxt.mem_write_val=pipe_m.alu_result;
            HAZ_HI_M:pipe_m_nxt.mem_write_val=pipe_m.hi_result;
            HAZ_LO_M:pipe_m_nxt.mem_write_val=pipe_m.lo_result;
            HAZ_HI_W:pipe_m_nxt.mem_write_val=pipe_w.hi_result;
            HAZ_LO_W:pipe_m_nxt.mem_write_val=pipe_w.lo_result;
            default: begin
                pipe_m_nxt.mem_write_val=pipe_e.src_b;
            end
        endcase
    end

    always_comb begin
        case (pipe_e.control.alu_src_b)
            ALU_SRC_IMM_H,ALU_SRC_IMM_Z,ALU_SRC_IMM_S:alu_input_b=pipe_e.imm;
            ALU_SRC_RT,ALU_SRC_HI,ALU_SRC_LO:alu_input_b=pipe_m_nxt.mem_write_val;
            default: begin
                alu_input_b=32'd0;
            end
        endcase
    end

    // ALU
    i64 alu_ans;
    i33 alu_tmp;

    always_comb begin
        pipe_m_nxt.alu_result=32'd0;
        pipe_m_nxt.hi_result=32'd0;
        pipe_m_nxt.lo_result=32'd0;
        alu_ans='0;
        alu_tmp='0;
        case (pipe_e.control.alu_op)
            // ALU_OP_PLUS:    pipe_m_nxt.alu_result=  alu_input_a + alu_input_b;
            // ALU_OP_MINUS:   pipe_m_nxt.alu_result=  alu_input_a - alu_input_b;
            ALU_OP_PLUS:begin
                if(pipe_e.control.exc_flag!=EXC_Ov)begin
                    pipe_m_nxt.alu_result=  alu_input_a + alu_input_b;
                end else begin
                    alu_tmp={alu_input_a[31],alu_input_a}+{alu_input_b[31],alu_input_b};
                    pipe_m_nxt.alu_result=alu_tmp[31:0];
                    if(alu_tmp[32]!=alu_tmp[31])pipe_m_nxt.exc_code.Ov=1'b1;
                end
            end
            ALU_OP_MINUS:begin
                if(pipe_e.control.exc_flag!=EXC_Ov)begin
                    pipe_m_nxt.alu_result=  alu_input_a - alu_input_b;
                end else begin
                    alu_tmp={alu_input_a[31],alu_input_a}-{alu_input_b[31],alu_input_b};
                    pipe_m_nxt.alu_result=alu_tmp[31:0];
                    if(alu_tmp[32]!=alu_tmp[31])pipe_m_nxt.exc_code.Ov=1'b1;
                end
            end
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
            ALU_OP_MULTU:begin
                alu_ans={32'b0,alu_input_a}*{32'b0,alu_input_b};
                pipe_m_nxt.hi_result=alu_ans[63:32];
                pipe_m_nxt.lo_result=alu_ans[31:0];
            end
            ALU_OP_MULT:begin
                alu_ans=signed'({{32{alu_input_a[31]}},alu_input_a})*signed'({{32{alu_input_b[31]}},alu_input_b});
                pipe_m_nxt.hi_result=alu_ans[63:32];
                pipe_m_nxt.lo_result=alu_ans[31:0];
            end
            ALU_OP_DIVU:begin
                alu_tmp={1'b0,alu_input_a}/{1'b0,alu_input_b};
                pipe_m_nxt.lo_result=alu_tmp[31:0];
                alu_tmp={1'b0,alu_input_a}%{1'b0,alu_input_b};
                pipe_m_nxt.hi_result=alu_tmp[31:0];
            end
            ALU_OP_DIV:begin
                pipe_m_nxt.lo_result=signed'(alu_input_a)/signed'(alu_input_b);
                pipe_m_nxt.hi_result=signed'(alu_input_a)%signed'(alu_input_b);
            end
            default: begin
                
            end
        endcase
    end

    // Memory
    i8 interrupt_flag;
    i1 timer_int,timer_int_pre;
    
    assign timer_int=timer_int_pre|(cp0.Count==cp0.Compare);
    assign interrupt_flag=cp0.Status[0]&(cp0.Status[1]==1'b0)&(({ext_int,2'b00}|cp0.Cause[15:8]|{timer_int,7'b0})&cp0.Status[15:8]);
    assign pipe_m.exc_code.Int=(|interrupt_flag);

    assign pipe_m.exc_code.BP=pipe_m.exc_code.BP|(pipe_m.control.exc_flag==EXC_BP);
    assign pipe_m.exc_code.Sys=(pipe_m.control.exc_flag==EXC_Sys);

    // Int AdEI AdEL AdES Sys BP RI Ov

    always_comb begin
        if(pipe_m.control.exc_flag==EXC_Eret)begin
            flush_before_w=1'b1;
            cp0_nxt.Status[1]=1'b0;
        end else if(|pipe_m.exc_code)begin
            flush_before_w=1'b1;
            if(pipe_m.exc_code.Int)cp0_nxt.Cause[6:2]=5'h00;
            else if(pipe_m.exc_code.AdEI)begin
                cp0_nxt.Cause[6:2]=5'h04;
                cp0_nxt.BadVAddr=pipe_m.pc;
            end else if(pipe_m.exc_code.RI)cp0_nxt.Cause[6:2]=5'h0a;
            else if(pipe_m.exc_code.Ov)cp0_nxt.Cause[6:2]=5'h0c;
            else if(pipe_m.exc_code.BP)cp0_nxt.Cause[6:2]=5'h09;
            else if(pipe_m.exc_code.Sys)cp0_nxt.Cause[6:2]=5'h08;
            else if(pipe_m.exc_code.AdEL|pipe_m.exc_code.AdES)begin
                cp0_nxt.Cause[6:2]=(pipe_m.exc_code.AdEL)?5'h04:5'h05;
                cp0_nxt.BadVAddr=pipe_m.alu_result;
            end else begin
                flush_before_w=1'b0;
                cp0_nxt.Cause[6:2]=5'h1f;
            end
            cp0_nxt.Status[1]=1'b1;
            if(pipe_m.is_cond)begin
                cp0_nxt.EPC=pipe_m.pc-32'd4;
                cp0_nxt.Cause[31]=1'b1;
            end else begin
                cp0_nxt.EPC=pipe_m.pc;
                cp0_nxt.Cause[31]=1'b0;
            end
        end else begin
            flush_before_w=1'b0;
            cp0_nxt.Cause[6:2]=5'h1f;
        end
    end

    // TODO 时钟中断 cp0初始化

    assign pipe_w_nxt.control=pipe_m.control;
    assign pipe_w_nxt.pc_plus8=pipe_m.pc_plus8;
    assign pipe_w_nxt.reg_write_dst=pipe_m.reg_write_dst;
    assign pipe_w_nxt.alu_result=pipe_m.alu_result;
    // assign pipe_w_nxt.hi_result=pipe_m.hi_result;
    // assign pipe_w_nxt.lo_result=pipe_m.lo_result;
    assign pipe_w_nxt.pc=pipe_m.pc;

    // assign pipe_w_nxt.read_data=32'd0;
    assign pipe_w_nxt.read_data=dresp.data;

    assign dreq.valid=(pipe_m.control.reg_write_val==VAL_MEM)|pipe_m.control.mem_write_en;
    // assign dreq.strobe={4{pipe_m.control.mem_write_en}};
    assign dreq.size=MSIZE4;

    

    always_comb begin
        dreq.addr=pipe_m.alu_result;
        if(pipe_m.control.mem_write_en)begin
            case (pipe_m.control.ls_flag)
                LS_WORD:begin
                    dreq.strobe=4'b1111;
                    dreq.data=pipe_m.mem_write_val;
                    if(dreq.addr&32'd3!='0)begin
                        pipe_m.exc_code.AdES=1'b1;
                        dreq.addr=dreq.addr&32'hfffffffc;
                    end
                end
                LS_HALFW:begin
                    dreq.strobe=4'b11<<pipe_m.alu_result[1:0];
                    dreq.data={2{pipe_m.mem_write_val[15:0]}};
                    if(dreq.addr&32'd1!='0)begin
                        pipe_m.exc_code.AdES=1'b1;
                        dreq.addr=dreq.addr&32'hfffffffe;
                    end
                end
                LS_BTYE:begin
                    dreq.strobe=4'b1<<pipe_m.alu_result[1:0];
                    dreq.data={4{pipe_m.mem_write_val[7:0]}};
                end
                default: begin
                    dreq.strobe=4'b0;
                    dreq.data=32'd0;
                end
            endcase
        end else begin
            dreq.strobe=4'b0;
            dreq.data=32'd0;
            if(pipe_m.control.reg_write_val==VAL_MEM)begin
                case(pipe_m.control.ls_flag)
                    LS_WORD:begin
                        if(dreq.addr&32'd3!='0)begin
                            pipe_m.exc_code.AdEL=1'b1;
                            dreq.addr=dreq.addr&32'hfffffffc;
                        end
                    end
                    LS_HALFW:begin
                        if(dreq.addr&32'd1!='0)begin
                            pipe_m.exc_code.AdEL=1'b1;
                            dreq.addr=dreq.addr&32'hfffffffe;
                        end
                    end
                endcase
            end
        end
    end

    always_comb begin
        case (pipe_m.control.hilo_write_en)
            2'b01,2'b10:begin
                pipe_w_nxt.hi_result=pipe_m.alu_result;
                pipe_w_nxt.lo_result=pipe_m.alu_result;
            end 
            default: begin
                pipe_w_nxt.hi_result=pipe_m.hi_result;
                pipe_w_nxt.lo_result=pipe_m.lo_result;
            end
        endcase
    end

    // assign dreq.addr=pipe_m.alu_result;
    // assign dreq.data=pipe_m.mem_write_val;

    // Write Back
    word_t read_data,read_data_aligned;
    addr_t wpc /* verilator public_flat_rd */;
    i8 read_data_byte;
    i16 read_data_halfw;

    // assign read_data=dresp.data;
    assign read_data=pipe_w.read_data;
    assign wpc=pipe_w.pc;
    // assign wpc=32'hbfc00000;

    always_comb begin
        wd3=32'd0;
        case (pipe_w.control.reg_write_val)
            VAL_ALU_RES:wd3=pipe_w.alu_result;
            VAL_MEM:begin
                read_data_aligned=read_data>>{pipe_w.alu_result[1:0],3'b0};
                read_data_byte=read_data_aligned[7:0];
                read_data_halfw=read_data_aligned[15:0];
                case (pipe_w.control.ls_flag)
                    LS_BTYE: wd3=`SIGN_EXTEND(read_data_byte ,32);
                    LS_BTYE_U:wd3=`ZERO_EXTEND(read_data_byte,32);
                    LS_HALFW:wd3=`SIGN_EXTEND(read_data_halfw,32);
                    LS_HALFW_U:wd3=`ZERO_EXTEND(read_data_halfw,32);
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

    // assign pipe_f_nxt.pc=(pc_select)?pc_branch:pipe_d_nxt.pc_plus4;
    always_comb begin
        if(flush_before_w)begin
            pipe_f_nxt.pc=(pipe_m.control.exc_flag==EXC_Eret)?cp0.EPC:32'hbfc00380;
        end else begin
            pipe_f_nxt.pc=(pc_select)?pc_branch:pipe_d_nxt.pc_plus4;
        end
    end

    // Sequential Logic
    always_ff @( posedge clk ) begin
        if((~resetn)|flush_before_w)begin
            pipe_f.pc<=32'hbfc0_0000;
        end else if(~stall_f)begin
            pipe_f<=pipe_f_nxt;
        end else begin
            
        end
    end

    always_ff @( posedge clk ) begin
        if((~resetn)|flush_before_w)begin
            pipe_d.instr<=32'hxxxxxxxx;
            pipe_d.pc<=32'hxxxxxxxx;
            pipe_d.pc_plus4<=32'hxxxxxxxx;
            pipe_d.is_cond<=1'b0;
            pipe_d.exc_code<='0;
        end else if(~stall_d)begin
            pipe_d<=pipe_d_nxt;
        end else begin
            
        end
    end

    always_ff @( posedge clk ) begin
        if((~resetn) | flush_e | flush_before_w)begin
            pipe_e.control<={
                ALU_SRC_NONE,
                ALU_SRC_NONE,
                ALU_OP_NONE,
                BR_NONE,
                5'b00000,
                VAL_NONE,
                REG_DST_NONE,
                LS_NONE,
                EXC_None
            };
            pipe_e.is_cond<=1'b0;
            pipe_e.src_a<=32'd0;
            pipe_e.src_b<=32'd0;
            pipe_e.rs<=5'd0;
            pipe_e.rt<=5'd0;
            pipe_e.rd<=5'd0;
            pipe_e.imm<=32'd0;
            pipe_e.shamt<=5'd0;
            pipe_e.reg_write_dst<=5'd0;
            pipe_e.pc_plus8<=32'hxxxxxxxx;
            pipe_e.exc_code<='0;
        end else if(~stall_e) begin
            pipe_e<=pipe_e_nxt;
        end else begin
            
        end
    end

    always_ff @( posedge clk ) begin
        if((~resetn)|flush_before_w)begin
            pipe_m.control<={
                ALU_SRC_NONE,
                ALU_SRC_NONE,
                ALU_OP_NONE,
                BR_NONE,
                5'b00000,
                VAL_NONE,
                REG_DST_NONE,
                LS_NONE,
                EXC_None
            };
            pipe_m.pc<=32'hxxxxxxxx;
            pipe_m.is_cond<=1'b0;
            pipe_m.alu_result<=32'd0;
            pipe_m.mem_write_val<=32'd0;
            pipe_m.reg_write_dst<=5'd0;
            pipe_m.pc_plus8<=32'hxxxxxxxx;
            pipe_m.exc_code<='0;
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
                5'b00000,
                VAL_NONE,
                REG_DST_NONE,
                LS_NONE,
                EXC_None
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
