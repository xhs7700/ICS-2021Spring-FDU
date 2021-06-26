typedef logic [31:0] paddr_t;
typedef logic [31:0] vaddr_t;

module AddressTranslator (
    input vaddr_t vaddr,
    output paddr_t paddr,
    output logic uncached
);
    assign paddr[27:0]=vaddr[27:0];
    assign uncached=(vaddr[31:28]==4'ha)|(vaddr[31:28]==4'hb);
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