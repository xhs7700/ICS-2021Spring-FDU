`ifndef MYCPU_INSTR_SVH
`define MYCPU_INSTR_SVH

`include "common.svh"

typedef i5  shamt_t;
typedef i16 imm_t;
typedef i26 long_imm_t;
typedef i32 instr_t;

typedef enum i6 {
    OP_RTYPE = 6'b000000,
    OP_BTYPE = 6'b000001,
    OP_J     = 6'b000010,
    OP_JAL   = 6'b000011,
    OP_BEQ   = 6'b000100,
    OP_BNE   = 6'b000101,
    OP_BLEZ  = 6'b000110,
    OP_BGTZ  = 6'b000111,
    OP_ADDI  = 6'b001000,
    OP_ADDIU = 6'b001001,
    OP_SLTI  = 6'b001010,
    OP_SLTIU = 6'b001011,
    OP_ANDI  = 6'b001100,
    OP_ORI   = 6'b001101,
    OP_XORI  = 6'b001110,
    OP_LUI   = 6'b001111,
    OP_COP0  = 6'b010000,
    OP_LB    = 6'b100000,
    OP_LH    = 6'b100001,
    OP_LW    = 6'b100011,
    OP_LBU   = 6'b100100,
    OP_LHU   = 6'b100101,
    OP_SB    = 6'b101000,
    OP_SH    = 6'b101001,
    OP_SW    = 6'b101011
} opcode_t;

typedef enum i6 {
    FN_SLL     = 6'b000000,
    FN_SRL     = 6'b000010,
    FN_SRA     = 6'b000011,
    FN_SRLV    = 6'b000110,
    FN_SRAV    = 6'b000111,
    FN_SLLV    = 6'b000100,
    FN_JR      = 6'b001000,
    FN_JALR    = 6'b001001,
    FN_SYSCALL = 6'b001100,
    FN_BREAK   = 6'b001101,
    FN_MFHI    = 6'b010000,
    FN_MTHI    = 6'b010001,
    FN_MFLO    = 6'b010010,
    FN_MTLO    = 6'b010011,
    FN_MULT    = 6'b011000,
    FN_MULTU   = 6'b011001,
    FN_DIV     = 6'b011010,
    FN_DIVU    = 6'b011011,
    FN_ADD     = 6'b100000,
    FN_ADDU    = 6'b100001,
    FN_SUB     = 6'b100010,
    FN_SUBU    = 6'b100011,
    FN_AND     = 6'b100100,
    FN_OR      = 6'b100101,
    FN_XOR     = 6'b100110,
    FN_NOR     = 6'b100111,
    FN_SLT     = 6'b101010,
    FN_SLTU    = 6'b101011
} funct_t;

`endif