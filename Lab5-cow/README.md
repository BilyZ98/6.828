# Lab5: copy-on-write for xv6

## record might not be good enough
```
char record[(PHYSTOP-KERNBASE)/PGSIZE];
```
this solution to record each page's reference count might occupy too much memory  
kernel size: about 176KB, record size: 128MB/4KB*sizeof(char) = 32KB

## race occurs
there is a race between  
checking/modifying kalloc.c's record  
and  
copying content of memory.

solution:  
use `kem.lock`  
see `kuncopy_begin` and `kuncopy_end`

## RECORD macro
```
#define RECORD(p) (record[((uint64)p-KERNBASE)/PGSIZE])
```
forget to add `-KERNBASE` at the beginning

## In copyout
in `copyout`, we should test page faults and call `uvmcow`.
```
if(va0 < MAXVA && !(*walk(pagetable, va0, 0) & PTE_W))
    uvmcow(pagetable, va0);
```

just adding handler in `kerneltrap` is not enough.
```
if(scause == 15){
    // Store page fault
    // might be using copy-on-write
    printf("15 here\n");
    if(!uvmcow(myproc()->pagetable, r_stval())){
      printf("scause %p\n", scause);
      printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
      // if panic here, usertests sbrkbasic will fail.
      // panic("kerneltrap");
    }
  }
```

## time spent
5 hours
