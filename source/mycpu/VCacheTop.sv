`include "access.svh"
`include "common.svh"

module VCacheTop (
    input logic clk, resetn,

    input  dbus_req_t  dreq,
    output dbus_resp_t dresp,
    output cbus_req_t  creq,
    input  cbus_resp_t cresp
);
    `include "bus_decl"

    cbus_req_t  dcreq;
    cbus_resp_t dcresp;

    assign creq = dcreq;
    assign dcresp = cresp;
    DCache top(.*);

    // /* verilator tracing_off */
    word_t [63:0] mem /* verilator public_flat_rd */;
    // /* verilator tracing_on */
    
    for(genvar index=0;index<4;index++)begin
        for(genvar pos=0;pos<4;pos++)begin
            for(genvar offset=0;offset<4;offset++)begin
                assign mem[index*16+pos*4+offset]=top.cache[index][pos][offset];
            end
        end
    end

endmodule
