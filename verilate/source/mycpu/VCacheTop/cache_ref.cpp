#include "mycache.h"
#include "cache_ref.h"

CacheRefModel::CacheRefModel(MyCache *_top, size_t memory_size)
    : top(_top), scope(top->VCacheTop), mem(memory_size) {
    /**
     * TODO (Lab3) setup reference model :)
     */

    mem.set_name("ref");
}

void CacheRefModel::reset() {
    log_debug("ref: reset()\n");
    for(int i=0;i<4;i++)
        cache[i].clear();
    mem.reset();
}

auto CacheRefModel::load(addr_t addr, AXISize size) -> word_t {
    log_debug("ref: load(0x%x, %d)\n", addr, 1 << size);
    int index=(addr>>4)&3;
    return read(index,addr);
}

void CacheRefModel::store(addr_t addr, AXISize size, word_t strobe, word_t data) {
    log_debug("ref: store(0x%x, %d, %x, \"%08x\")\n", addr, 1 << size, strobe, data);
    int index=(addr>>4)&3;
    update(index,addr,strobe,data);
}

void CacheRefModel::check_internal() {
    log_debug("ref: check_internal()\n");
    for(int index=0;index<4;index++)
        for(int pos=0;pos<4;pos++){
            if(!cache[index].valid[pos])continue;
            for(int offset=0;offset<4;offset++)
                asserts(
                    cache[index].line[pos][offset]==scope->mem[(index<<4)|(pos<<2)|offset],
                    "reference model's internal state is different from RTL model."
                    " at mem[%x][%x][%x], expected = %08x, got = %08x",
                    index,pos,offset,cache[index].line[pos][offset],scope->mem[(index<<4)|(pos<<2)|offset]
                );
        }
}

void CacheRefModel::check_memory() {
    log_debug("ref: check_memory()\n");
    asserts(mem.dump(0, mem.size()) == top->dump(), "reference model's memory content is different from RTL model");
}
