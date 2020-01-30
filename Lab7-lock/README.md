# Lab7 - lock

## ok to not turn off interrupts
Because free page just go to original(before interrupt) cpu's freelist.  
Might be good to turn off interrupts when allocating free page.

## bcache solution1
just split the original list into 3 lists,  
each list caches the blocks with corresponding blockno(mod 3).

solution2(better):  
I just split the whole list on average.  
Maintaining another list for free buffer cache could be more flexible,  
in case blocks r/w all have the same remainder mod by 3.  
More detail: blocks in free list have 0 refcnt, while blocks in any of the 3 lists have non-zero refcont.  
Then the implementation in `bget`&`brelse` could be clear.
