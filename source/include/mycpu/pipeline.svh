`ifndef MYCPU_PIPELINE_SVH
`define MYCPU_PIPELINE_SVH

`include "common.svh"
`include "mycpu/control.svh"
`include "mycpu/instr.svh"

typedef struct packed {
    word_t BadVAddr;
    word_t Count;
    word_t CountFlag;
    word_t Compare;
    word_t Status;
    word_t Cause;
    word_t EPC;
} cp0_reg_t;

typedef struct packed {
    i1 Int;
    i1 AdEI;
    i1 AdEL;
    i1 AdES;
    i1 Sys;
    i1 BP;
    i1 RI;
    i1 Ov;
} exc_code_t;

typedef struct packed {
    addr_t pc;
} pipeline_reg_fetch_t;

typedef struct packed {
    addr_t pc;
    instr_t instr;
    addr_t pc_plus4;
    i1 is_cond;
    exc_code_t exc_code;
} pipeline_reg_decode_t;

typedef struct packed {
    addr_t      pc;
    control_t   control;
    word_t      src_a;
    word_t      src_b;
    regidx_t    rs;
    regidx_t    rt;
    regidx_t    rd;
    word_t      imm;
    shamt_t     shamt;
    regidx_t    reg_write_dst;
    addr_t      pc_plus8;
    i1          is_cond;
    exc_code_t  exc_code;
} pipeline_reg_execute_t;

typedef struct packed {
    addr_t pc;
    control_t control;
    i32 alu_result;
    word_t hi_result;
    word_t lo_result;
    word_t mem_write_val;
    regidx_t reg_write_dst;
    addr_t pc_plus8;
    i1 is_cond;
    exc_code_t exc_code;
} pipeline_reg_memory_t;

typedef struct packed {
    addr_t pc;
    control_t control;
    word_t read_data;
    word_t alu_result;
    word_t hi_result;
    word_t lo_result;
    regidx_t reg_write_dst;
    addr_t pc_plus8;
} pipeline_reg_write_t;

`endif