`include "common.svh"
`include "mycpu/control.svh"

module Mult (
    input word_t a,b,
    input ctrl_alu_op_t op,
    output word_t hi,lo
);
    i64 ans;
    always_comb begin
        case (op)
            ALU_OP_MULTU: begin
                ans={32'b0,a}*{32'b0,b};
                hi=ans[63:32];lo=ans[31:0];
            end
            ALU_OP_MULT:begin
                ans=signed'({{32{a[31]}},a})*signed'({{32{b[31]}},b});
                hi=ans[63:32];lo=ans[31:0];
            end
            ALU_OP_DIVU:begin
                ans='0;
                lo={1'b0,a}/{1'b0,b};
                hi={1'b0,a}%{1'b0,b};
            end
            ALU_OP_DIV:begin
                ans='0;
                lo=signed'(a)/signed'(b);
                hi=signed'(a)%signed'(b);
            end
            default: begin
                {hi,lo,ans}='0;
            end
        endcase
    end
endmodule