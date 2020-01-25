// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

static void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run {
  struct run *next;
};

struct {
  struct spinlock lock;
  struct run *freelist;
} kmem;

#define RECORD(p) (record[((uint64)p-KERNBASE)/PGSIZE])
char record[(PHYSTOP-KERNBASE)/PGSIZE];

void
kinit()
{
  initlock(&kmem.lock, "kmem");
  freerange(end, (void*)PHYSTOP);
}

static void
freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    RECORD(p) = 1;
    kfree(p);
  }
}

// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");

  // Decremnet the reference count to page start at pa
  // Free its memory if the count equals to 0
  acquire(&kmem.lock);
  if(--RECORD(pa) != 0){
    release(&kmem.lock);
    return;
  }

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);

  r = (struct run*)pa;
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
  struct run *r;

  acquire(&kmem.lock);
  r = kmem.freelist;
  if(r){
    kmem.freelist = r->next;
    RECORD(r) = 1;
  }
  release(&kmem.lock);

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
  return (void*)r;
}

// Copy the page that is already allocated.
// Simply increment its reference count in record.
void
kcopy(void *pa)
{
  acquire(&kmem.lock);
  if(RECORD(pa)++ == 0)
    panic("kcopy invalid page");
  release(&kmem.lock);
}

// Used in uvmcow function.
// If count > 1, which means we need to allocate new page,
// then return 1 and,
// in kuncopy_end, decrement the page's reference count.
// If count == 1, which means only one reference left,
// then return 0 and,
// we no need to allocate new page, i.e., we just this old page.
void *
kuncopy_begin(void *pa)
{
  acquire(&kmem.lock);
  if(RECORD(pa) == 0)
    panic("kuncopy");
  if(RECORD(pa) == 1)
    return 0;
  
  struct run *r;
  r = kmem.freelist;
  if(r){
    kmem.freelist = r->next;
    RECORD(r) = 1;
    memset((char*)r, 5, PGSIZE); // fill with junk
  }

  return (void *)r;
}

void
kuncopy_end(void *pa, int succeed)
{
  if(succeed && RECORD(pa) > 1)
    RECORD(pa)--;
  release(&kmem.lock);
}
