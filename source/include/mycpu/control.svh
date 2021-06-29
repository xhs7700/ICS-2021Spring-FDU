`ifndef MYCPU_CONTROL_SVH
`define MYCPU_CONTROL_SVH

`include "common.svh"

typedef enum i4 { 
    ALU_SRC_NONE,
    ALU_SRC_RS,
    ALU_SRC_RT,
    ALU_SRC_RD,
    ALU_SRC_IMM_S,
    ALU_SRC_IMM_Z,
    ALU_SRC_IMM_H,
    ALU_SRC_SHAMT,
    ALU_SRC_ZERO,
    ALU_SRC_HI,
    ALU_SRC_LO,
    ALU_SRC_C0
} ctrl_alu_src_t;

typedef enum i5 { 
    ALU_OP_NONE,
    ALU_OP_PLUS,
    ALU_OP_MINUS,
    ALU_OP_AND,
    ALU_OP_OR,
    ALU_OP_NOR,
    ALU_OP_XOR,
    ALU_OP_SLL,
    ALU_OP_SLLV,
    ALU_OP_SRA,
    ALU_OP_SRAV,
    ALU_OP_SRL,
    ALU_OP_SRLV,
    ALU_OP_SLT,
    ALU_OP_SLTU,
    ALU_OP_MULTU,
    ALU_OP_MULT,
    ALU_OP_DIVU,
    ALU_OP_DIV
 } ctrl_alu_op_t;

typedef enum i4 { 
    BR_NONE,
    BR_BEQ,
    BR_BNE,
    BR_JR,
    BR_J,
    BR_BGEZ,
    BR_BGTZ,
    BR_BLEZ,
    BR_BLTZ
 } ctrl_branch_t;

typedef enum i3 { 
    VAL_NONE,
    VAL_ALU_RES,
    VAL_MULT_RES,
    VAL_MEM,
    VAL_PC
 } ctrl_reg_val_t;

typedef enum i2 { 
    REG_DST_NONE,
    REG_DST_RT,
    REG_DST_RD,
    REG_DST_RA
 } ctrl_reg_dst_t;

typedef enum i3 { 
    HAZ_DEFAULT,
    HAZ_ALU_RES_E,
    HAZ_ALU_RES_M,
    HAZ_RES_W,
    HAZ_HI_M,
    HAZ_LO_M,
    HAZ_HI_W,
    HAZ_LO_W
 } hazard_forward_t;

typedef enum i3 { 
    LS_BTYE,
    LS_BTYE_U,
    LS_HALFW,
    LS_HALFW_U,
    LS_WORD,
    LS_NONE
} load_store_t;

typedef enum i3 { 
    EXC_None,
    EXC_Ov,
    EXC_BP,
    EXC_Eret,
    EXC_Sys
 } exc_t;

typedef struct packed {
    ctrl_alu_src_t alu_src_a;
    ctrl_alu_src_t alu_src_b;
    ctrl_alu_op_t alu_op;
    ctrl_branch_t branch;
    i1 reg_write_en;
    i1 mem_write_en;
    i2 hilo_write_en;
    i1 c0_write_en;
    ctrl_reg_val_t reg_write_val;
    ctrl_reg_dst_t reg_dst;
    load_store_t ls_flag;
    exc_t exc_flag;
} control_t;

`endif