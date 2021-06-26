`include "common.svh"
`include "mycpu/cache.svh"

module DCache #(
    parameter int OFFSET_BITS=4,
    parameter int INDEX_BITS=2,
    localparam int LINE_BOUND=OFFSET_BITS-3,
    localparam int TAG_BITS=32-OFFSET_BITS-INDEX_BITS,
    localparam int OFFSET_MAX=OFFSET_BITS-1,
    localparam int INDEX_MAX=INDEX_BITS-1,
    localparam int TAG_MAX=31-OFFSET_BITS-INDEX_BITS,
    localparam int SET_MAX=(1<<INDEX_BITS)-1,
    localparam int LINE_MAX=(1<<(OFFSET_BITS-2))-1
) (
    input logic clk, resetn,

    input  dbus_req_t  dreq,
    output dbus_resp_t dresp,
    output cbus_req_t  dcreq,
    input  cbus_resp_t dcresp
);
    typedef logic[TAG_MAX:0] tag_t;
    typedef logic[INDEX_MAX:0] index_t;
    typedef logic[OFFSET_MAX:0] offset_t;
    typedef logic[1:0] position_t;
    typedef word_t[LINE_MAX:0] cache_line_t;
    typedef cache_line_t[3:0] cache_set_t;
    typedef struct packed {
        tag_t tag;
        i1 valid;
        i1 dirty;
    } meta_t;
    typedef meta_t[3:0] meta_set_t;

    meta_set_t[SET_MAX:0] meta;
    cache_set_t[SET_MAX:0] cache;

    tag_t tag;
    cache_state_t state;
    index_t index;
    
    /* verilator lint_off UNUSED */
    dbus_req_t req;
    offset_t offset;
    /* verilator lint_off UNUSED */

    meta_set_t foo;
    position_t pos;
    logic[LINE_BOUND:0] offset_in;

    assign foo=meta[index];

    always_comb begin
        pos=2'b00;
        if(foo[0].tag==tag)pos=2'b00;
        else if(foo[1].tag==tag)pos=2'b01;
        else if(foo[2].tag==tag)pos=2'b10;
        else if(foo[3].tag==tag)pos=2'b11;
        else pos=tag[1:0]^tag[3:2]^tag[5:4]^tag[7:6];
    end

    assign dresp.addr_ok=(state==IDLE);
    assign dresp.data_ok=(state==READY);
    assign dresp.data=cache[index][pos][offset[OFFSET_MAX:2]];

    assign dcreq.valid=(state==FLUSH)|(state==FETCH);
    assign dcreq.is_write=(state==FLUSH);
    assign dcreq.size=MSIZE4;
    assign dcreq.addr={meta[index][pos].tag,index,4'b0000};
    assign dcreq.strobe=4'b1111;
    assign dcreq.data=cache[index][pos][offset_in];
    assign dcreq.len=MLEN4;

    word_t val;
    always_comb begin
        val=cache[index][pos][offset[OFFSET_MAX:2]];
        if(req.strobe[0])val[7:0]=req.data[7:0];
        if(req.strobe[1])val[15:8]=req.data[15:8];
        if(req.strobe[2])val[23:16]=req.data[23:16];
        if(req.strobe[3])val[31:24]=req.data[31:24];
    end

    always_ff @( posedge clk ) begin
        if(~resetn)begin
            state<=IDLE;
            {req,offset}<='0;
            meta<='0;
        end else begin
            case (state)
                IDLE:begin
                    if(dreq.valid)begin
                        {tag,index,offset}<=dreq.addr;
                        req<=dreq;
                        offset_in<=2'b00;
                        state<=SEARCH;
                    end else begin
                        
                    end
                end
                SEARCH:begin
                    if(meta[index][pos].tag==tag)state<=HIT;
                    else state<=MISS;
                end
                HIT:begin
                    if(~(meta[index][pos].valid | meta[index][pos].dirty))state<=FETCH;
                    else state<=READY;
                end
                MISS:begin
                    if(meta[index][pos].dirty)state<=FLUSH;
                    else begin
                        state<=HIT;
                        meta[index][pos].tag<=tag;
                        meta[index][pos].valid<=1'b0;
                        meta[index][pos].dirty<=1'b0;
                    end
                end
                FETCH:begin
                    if(dcresp.ready)begin
                        cache[index][pos][offset_in]<=dcresp.data;
                        if(dcresp.last)begin
                            state<=READY;
                            meta[index][pos].valid<=1'b1;
                            meta[index][pos].dirty<=1'b0;
                        end else begin
                            state<=FETCH;
                            offset_in<=offset_in+1;
                        end
                    end else begin
                        
                    end
                end
                FLUSH:begin
                    if(dcresp.ready)begin
                        if(dcresp.last)begin
                            state<=HIT;
                            meta[index][pos].tag<=tag;
                            meta[index][pos].valid<=1'b0;
                            meta[index][pos].dirty<=1'b0;
                            offset_in<=2'b00;
                        end else begin
                            state<=FLUSH;
                            offset_in<=offset_in+1;
                        end
                    end else begin
                        
                    end
                end
                READY:begin
                    if(req.strobe!=4'b0000)begin
                        cache[index][pos][offset[OFFSET_MAX:2]]<=val;
                        meta[index][pos].valid<=1'b0;
                        meta[index][pos].dirty<=1'b1;
                    end else begin
                        
                    end
                    state<=IDLE;
                end
                default:begin
                    state<=IDLE;
                    {req,offset}<='0;
                end
            endcase
        end
    end

    `UNUSED_OK({clk, resetn, dreq, dcresp});
endmodule
