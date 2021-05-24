`include "common.svh"
`include "mycpu/control.svh"

module FlipFlop #(
    parameter type element_t=i32
) (
    input logic clk,resetn,en,clear,
    input element_t pipe_reg_nxt,
    output element_t pipe_reg
);
    always_ff @( posedge clk ) begin
        if(resetn & (~clear))begin
           if(en) pipe_reg<=pipe_reg_nxt; 
        end else begin
            pipe_reg<='0;
        end
    end
endmodule