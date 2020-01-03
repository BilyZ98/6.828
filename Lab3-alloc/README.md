## easy for file.c
just use `bd_malloc` and `bd_free`

## bd_initfree and bd_initfree_pair just amazing!
before:
```
bd: memory sz is 134045696 bytes; allocate an size array of length 24
bd: 3146512 meta bytes for managing 134217728 bytes of memory
bd: 0x2a000 bytes unavailable
```

after:
```
bd: memory sz is 134049792 bytes; allocate an size array of length 24
bd: 2097936 meta bytes for managing 134217728 bytes of memory
bd: 0x29000 bytes unavailable
```

## still have to optimize how the kernel uses the memory
solution: dynamically allocating proc structures, not easy!!!(may done after learning **processes and switching**)  
fail on usertests' forkfork:
```
forkfork test
scause 0x000000000000000d
sepc=0x00000000800044e2 stval=0x80e7000010974509
panic: kerneltrap
```
but how to debug this kind of bugs?  
see branch *alloc-debug-dynamically-proc-struct*

## design problem of buddy system
Not good to use something like `(char *)p - bd_base`, because it might not be page aligned.  
Luckily, we have code in *kalloc.c* to align first:
```
void
kinit()
{
  char *p = (char *) PGROUNDUP((uint64) end);
  bd_init(p, (void*)PHYSTOP);
}
```

## sched lock in forkforkfork test (see commit `almost done lab3`)
due to putting `release(&lock)` after closing of *pipe* or *inode*
```
// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
  acquire(&lock);

  if(f->ref < 1)
    panic("fileclose");
  if(--f->ref > 0){
    release(&lock);
    return;
  }

  release(&lock);

  if(f->type == FD_PIPE){
    pipeclose(f->pipe, f->writable);
  } else if(f->type == FD_INODE || f->type == FD_DEVICE){
    begin_op(f->ip->dev);
    iput(f->ip);
    end_op(f->ip->dev);
  }
  bd_free(f);
  
  // release(&lock);    // sched lock
}
```