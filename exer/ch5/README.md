# ch5 - Exercise

## exercise 1
done, see kalloctest.c

## exercise 2
how to test?  
may modify `kfree` like this:
```
r->next = kmem.freelist;
acquire(&kmem.lock);
kmem.freelist = r;
memcnt += 1;
release(&kmem.lock);

checkmemcnt();
```
note: memcnt should decrement in `kalloc`

## exercise 3
see *kalloc-exer-3.c*:
```
acquire(&kilock);
  if(ki==0){
    ki = 1;
    release(&kilock);
    acquire(&kmem[0].lock);
    r = kmem[0].freelist;
    if(r)
      kmem[0].freelist = r->next;
    release(&kmem[0].lock);
  }
  else{
    ki = 0;
    release(&kilock);
    acquire(&kmem[1].lock);
    r = kmem[1].freelist;
    if(r)
      kmem[1].freelist = r->next;
    release(&kmem[1].lock);
  }
```
note: may not that good  
because ac&re `kilock` is not much faster than ac&re `kmem.lock`  
maybe should implement `acquire2`  
i.e., use `__sync_lock_test_and_set` to test two locks in turn

## exercise 4
see *ph.c*

## exercise 5
TODO