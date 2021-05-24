`include "common.svh"

typedef logic [31:0] paddr_t;
typedef logic [31:0] vaddr_t;

module AddressTranslator (
    input vaddr_t vaddr,
    output paddr_t paddr
);
    assign paddr[27:0]=vaddr[27:0];
    always_comb begin
        unique case (vaddr[31:28])
            4'h8: paddr[31:28] = 4'b0;
            4'h9: paddr[31:28] = 4'b1;
            4'ha: paddr[31:28] = 4'b0;
            4'hb: paddr[31:28] = 4'b1;
            default: paddr[31:28] = vaddr[31:28];
        endcase
    end
endmodule