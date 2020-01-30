// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run {
  struct run *next;
};

struct {
  struct spinlock lock;
  struct run *freelist;
  char name[6];
} kmem[NCPU];

void
kinit()
{
  for(int i=0;i<NCPU;i++){
    strncpy(kmem[i].name, "kmemi", 6);
    kmem[i].name[4] = '0' + i;
    initlock(&kmem[i].lock, kmem[i].name);
  }
  freerange(end, (void*)PHYSTOP);
}

void
freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    kfree(p);
}

// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
  int i;
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);

  r = (struct run*)pa;

  i = cpuid();
  acquire(&kmem[i].lock);
  r->next = kmem[i].freelist;
  kmem[i].freelist = r;
  release(&kmem[i].lock);
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
  int i, ii;
  struct run *r;

  push_off();
  i = cpuid();
  acquire(&kmem[i].lock);
  r = kmem[i].freelist;
  if(r == 0)
    goto steal;
  kmem[i].freelist = r->next;
  release(&kmem[i].lock);
  pop_off();

  memset((char*)r, 5, PGSIZE); // fill with junk
  return (void*)r;

steal:
  release(&kmem[i].lock);
  
  for(ii=(i+1)%NCPU;ii!=i;ii=(ii+1)%NCPU){
    acquire(&kmem[ii].lock);
    r = kmem[ii].freelist;
    if(r)
      break;
    release(&kmem[ii].lock);
  }
  if(ii == i){
    pop_off();
    return 0;
  }

  // ii is valid
  kmem[ii].freelist = r->next;
  release(&kmem[ii].lock);
  pop_off();
  memset((char*)r, 5, PGSIZE); // fill with junk
  return (void *)r;
}
