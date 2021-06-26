`ifndef MYCPU_CACHE_SVH
`define MYCPU_CACHE_SVH

`include "common.svh"

typedef enum i3 { 
    IDLE,
    SEARCH,
    HIT,
    MISS,
    FETCH,
    FLUSH,
    READY
 } cache_state_t;

`endif