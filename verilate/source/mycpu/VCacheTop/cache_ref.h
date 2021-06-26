#pragma once

#include "defs.h"
#include "memory.h"
#include "reference.h"

class MyCache;

class CacheRefModel final : public ICacheRefModel {
public:
    CacheRefModel(MyCache *_top, size_t memory_size);

    void reset();
    auto load(addr_t addr, AXISize size) -> word_t;
    void store(addr_t addr, AXISize size, word_t strobe, word_t data);
    void check_internal();
    void check_memory();

private:
    MyCache *top;
    VModelScope *scope;

    BlockMemory mem;
    struct CacheSet{
        word_t line[4][4];
        int tag[4],dirty[4],valid[4];
        void clear(){
            for(int i=0;i<4;i++){
                tag[i]=-1;
                dirty[i]=valid[i]=0;
            }
        }
    }cache[4];

    int find(int index,addr_t addr){
        int t=addr>>6,pos=-1;
        for(int i=0;i<4;i++)
            if(cache[index].tag[i]==t)
                pos=i;
        if(pos!=-1)return pos;

        pos=(t^(t>>2)^(t>>4)^(t>>6))&3;

        addr_t old_addr=(cache[index].tag[pos]<<6)|(index<<4);
        if(cache[index].dirty[pos])
            for(int i=0;i<4;i++)
                mem.store(old_addr|(i<<2),cache[index].line[pos][i],0xffffffff);
        addr_t new_addr=(t<<6)|(index<<4);
        for(int i=0;i<4;i++)
            cache[index].line[pos][i]=mem.load(new_addr|(i<<2));
        cache[index].tag[pos]=t;
        cache[index].dirty[pos]=0;
        cache[index].valid[pos]=1;
        return pos;
    }

    word_t read(int index,addr_t addr){
        int pos=find(index,addr);
        int offset=(addr>>2)&3;
        return cache[index].line[pos][offset];
    }

    void update(int index,addr_t addr, word_t strobe,word_t data){
        int pos=find(index,addr);
        int offset=(addr>>2)&3;
        auto mask=STROBE_TO_MASK[strobe];
        auto value=cache[index].line[pos][offset];

        value=(data&mask)|(value&(~mask));
        cache[index].line[pos][offset]=value;
        cache[index].dirty[pos]=1;
    }
};
