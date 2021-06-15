`include "common.svh"
module hilo (
    input logic clk,
    input i1 hi_we,lo_we,
    input word_t hi_data,lo_data,
    output word_t hi,lo
);
    word_t hi_nxt,lo_nxt;
    assign hi_nxt=(hi_we?hi_data:hi);
    assign lo_nxt=(lo_we?lo_data:lo);
    always_ff @( posedge clk ) begin
        {hi,lo}<={hi_nxt,lo_nxt};
    end
endmodule