`include "access.svh"
`include "common.svh"

module VTop (
    input logic clk, resetn,

    output cbus_req_t  oreq,
    input  cbus_resp_t oresp,

    input i6 ext_int
);
    `include "bus_decl"

    ibus_req_t  ireq,cireq,my_ireq;
    ibus_resp_t iresp,ciresp,my_iresp;
    dbus_req_t  dreq,cdreq,my_dreq;
    dbus_resp_t dresp,cdresp,my_dresp;
    cbus_req_t  icreq,  dcreq,cicreq,cdcreq;
    cbus_resp_t icresp, dcresp,cicresp,cdcresp;

    i1 iuncached,duncached;

    assign my_iresp=(iuncached)?iresp:ciresp;
    assign my_dresp=(duncached)?dresp:cdresp;

    assign ireq.valid=my_ireq.valid&iuncached;
    assign dreq.valid=my_dreq.valid&duncached;
    assign cireq.valid=my_ireq.valid&(~iuncached);
    assign cdreq.valid=my_dreq.valid&(~duncached);
    assign cireq.addr=ireq.addr;
    assign cdreq.addr=dreq.addr;

    assign dreq.size=my_dreq.size;
    assign dreq.strobe=my_dreq.strobe;
    assign dreq.data=my_dreq.data;
    
    assign cdreq.size=my_dreq.size;
    assign cdreq.strobe=my_dreq.strobe;
    assign cdreq.data=my_dreq.data;
    

    AddressTranslator AddressTranslator_inst1(.vaddr(my_ireq.addr),.paddr(ireq.addr),.uncached(iuncached));
    AddressTranslator AddressTranslator_inst2(.vaddr(my_dreq.addr),.paddr(dreq.addr),.uncached(duncached));

    MyCore core(
        .ireq(my_ireq),.iresp(my_iresp),
        .dreq(my_dreq),.dresp(my_dresp),
        .*);

    ICache ICache_inst(
        .ireq(cireq),.iresp(ciresp),
        .icreq(cicreq),.icresp(cicresp),
        .*);
    DCache DCache_inst(
        .dreq(cdreq),.dresp(cdresp),
        .dcreq(cdcreq),.dcresp(cdcresp),
        .*);

    IBusToCBus icvt(.*);
    DBusToCBus dcvt(.*);

    CBusArbiter #(.NUM_INPUTS(4)) mux(
        .ireqs({icreq, dcreq,cicreq,cdcreq}),
        .iresps({icresp, dcresp,cicresp,cdcresp}),
        .*
    );

    `UNUSED_OK({ext_int});
endmodule
