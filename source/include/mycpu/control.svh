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
    ALU_SRC_SHAMT
} ctrl_alu_src_t;

typedef enum i4 { 
    ALU_OP_NONE,
    ALU_OP_PLUS,
    ALU_OP_MINUS,
    ALU_OP_AND,
    ALU_OP_OR,
    ALU_OP_NOR,
    ALU_OP_XOR,
    ALU_OP_SLL,
    ALU_OP_SRA,
    ALU_OP_SRL,
    ALU_OP_SLT,
    ALU_OP_SLTU
 } ctrl_alu_op_t;

typedef enum i3 { 
    BR_NONE,
    BR_BEQ,
    BR_BNE,
    BR_JR,
    BR_J
 } ctrl_branch_t;

typedef enum i3 { 
    VAL_NONE,
    VAL_ALU_RES,
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
    HAZ_RES_W
 } hazard_forward_t;

typedef struct packed {
    ctrl_alu_src_t alu_src_a;
    ctrl_alu_src_t alu_src_b;
    ctrl_alu_op_t alu_op;
    ctrl_branch_t branch;
    i1 reg_write_en;
    i1 mem_write_en;
    ctrl_reg_val_t reg_write_val;
    ctrl_reg_dst_t reg_dst;
} control_t;

`endif