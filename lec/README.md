# Lec Record

## lec4 - Isolation & system call entry/exit

### address shift problem  
In xv6 book, section 2.8 Exercises have something different in my computer.  
i.e., address `0x3ffffff07e` become `0x3ffffff10e` in my computer actually.  
Troubleshooting:  
break at `0x3ffffff07e`, and then  
use gdb to `disas` a certain range of instructions, for example, `disas 0x3ffffff07e, 0x3fffffffff`

### write() start at ?
In lec notes, it says in sh.asm `write()` starts at address `0xd68`.  
In my computer, `write()` starts at address `0xd6a`.  
`ret`'s pc: `now we're back in the user program (pc = 0xd6e)`.  
In my computer, should be `0xd70`.

### **GOTCHA**  
In the lec note, `gdb has already executed this instruction (I don't know why)`  
This instruction is `csrrw a0, sscratch, a0`, first line in *uservec* of *kernel/trampoline.S* 

### next and step not working
in `usertrap` in *kernel/trap.c*
```
(gdb) next ... until syscall()
(gdb) step
```
solution: use `disas`, `break` and `continue`

## lec5 - Virtual memory (1)

### ld program
To understand why and how *kernel.ld* provide
`end` as address after the kernel data, that is used in
*kalloc.c*,  
we should be familar with the linker program and the linker script, etc.

### kernel's va direct-mapped into pa seems important
Section 3.3 from xv6 book:
```
The above code depends on physical memory being direct-mapped into the kernel virtual address space. For example, as walk descends levels of the page table, it pulls the (physical) address
of the next-level-down page table from a PTE (kernel/vm.c:82), and then uses that address as a
virtual address to fetch the PTE at the next level down (kernel/vm.c:80).
```

### Exercises of ch3: Page Tables
1. meaning of RISC-V's device tree???
2. analyze page table before and after calling sbrk(1)  
solution: check $satp and page table in trampoline.S   
(supervisor mode with kernel&user page table, can only check content of page tables under kernel page table, cause it's directed-mapped) (be careful of translation)  
user page table: 0x87f48000, 0x87f44000, 0x87f43000 (level 1,2,3 respectively)  
kernel page table: 0x87fff000
![](img/Screenshot_20191201_204040.png)
before and after (a new page allocated)
![](img/Screenshot_20191201_204526.png)

## lec7 - System calls, interrupts, exceptions

### traps in xv6
1. system call: ecall
2. exceptions: illegal instruction
3. interrupt: device
4. (timer interrupt)

### sec2
note: no nested kernel trap,  
i.e., once in `kernelvec` or `kerneltrap`, no another kernel trap
result: unless it calls `yield`, it must panic or return

```
It’s worth thinking through how the trap return happens if kerneltrap called yield due to
a timer interrupt.
```
what happens:
1. `yield()` change current proc's state to `RUNNABLE`, then call `sched()`
2. `sched()` call `swtch()` to save context and then switch to scheduler
3. In *swtch.S*: see how `swtch()` save context
4. previously in `kerneltrap()`: already save sepc and other things in the context(s0, ...); also can see in *kernel.asm*: 
```
00000000800026ba <kerneltrap>:
{
    800026ba:	7179                	addi	sp,sp,-48
    800026bc:	f406                	sd	ra,40(sp)
    800026be:	f022                	sd	s0,32(sp)
    800026c0:	ec26                	sd	s1,24(sp)
    800026c2:	e84a                	sd	s2,16(sp)
    800026c4:	e44e                	sd	s3,8(sp)
    800026c6:	1800                	addi	s0,sp,48
...
```

### sec3
!important: `ecall` => In trampoline.S: supervisor mode with no kernel page table.  
Without `ecall`, although user process can access kernel page from p->tf,  
it cannot use csr instruction to change `satp`.

### sec8
how does the kernel initialize `console` or how does `open("console")` work in *init.c*?  
how `read` system call make their way through the kernel to `consoleread`?

### sec9
```
However, the need for kernel code to be mindful that it might be suspended (due to
a timer interrupt) and later resume on a different CPU is the source of some complexity in xv6.
The kernel could be made somewhat simpler if device and timer interrupts only occurred while
executing user code.
```

### ch4 exercises, possible method
1. uartputc (kernel/uart.c:61) polls the UART device to wait for it to finish with the previous  
output character. Convert it to use interrupts instead.  
sol: reference `uartgetc` for example  
* first, enable transmitter empty interrupt - hardware config
```
The Interrupt Enable Register (IER) masks the incoming interrupts from receiver ready, transmitter empty, line status and modem status registers to the INT output pin.

IER BIT-0:
0=disable the receiver ready interrupt.
1=enable the receiver ready interrupt.

IER BIT-1:
0=disable the transmitter empty interrupt.
1=enable the transmitter empty interrupt.
```
* second, modify `consolewrite()` referencing `consoleread()` in *console.c* - process-level code
* third, add handler code in `devintr()` and `uartintr()` - handler-level code
2. Add a driver for an Ethernet card... kidding me! 

## lec9 - Processes and switching
### multi-taksing programs architecture
from lec note:
```
There are two main approaches to multi-tasking:
  Threads: program execution appears sequential.
  Events: programs are driven by arrival of events, like interrupts.
```

from [Stefan Hajnoczi's blog](http://blog.vmsplice.net/2011/03/qemu-internals-overall-architecture-and.html):
```
There are two popular architectures for programs that need to respond to events from multiple sources:
1. Parallel architecture splits work into processes or threads that can execute simultaneously.
    I will call this threaded architecture.
2. Event-driven architecture reacts to events by running a main loop that dispatches to event handlers.
    This is commonly implemented using the select(2) or poll(2) family of system calls to wait on multiple file descriptors.
```

### cannot find user/spin.c

### lock interaction between kernel thread and scheduler thread
```
remember sched() acquired the process's lock
  now scheduler releases it
  it may *look* like scheduler aquires then releases
    but in fact scheduler acquires, yield releases
    an yield acquires, scheduler releases
  unusual: the lock is released by a different thread than acquired it!
```

### proc's lock
```
p->lock protects multiple invariants:
  (invariant = true when p->lock not held, maybe not true if held)
  if RUNNING, CPU registers hold the values (not in p->context)
  if RUNNABLE, p->context holds its saved registers
  if RUNNABLE, no CPU is using its stack
  holding p->lock from yield() all the way to scheduler enforces:
    another CPU can't execute p until after this CPU stops using its stack
    interrupts off, so no nested yield()+swtch() during swtch() save/restore
```

## lec10 - sleep&wakeup

### why sleep should be wrapped in a loop - sec6
cauz multiple process might `sleep` on the same condition,    
`wakeup` wakes them all up,  
so only one process should `acquire` the condition lock,  
and others should `sleep` again(i.e. `sleep` in a loop)

### sec8 - Code: Wait, exit, and kill
detail of `exit`:
1. why `wakeup1(initproc)`  
  Need to `acquire(&initproc->lock)`, so this `wakeup1` should be called before any other
  proc->lock being acquired(otherwise, we violate the lock other).  
  Note: initproc might miss the forth-coming zombie children that is reparented to it, so adding/removing `wakeup1(initproc)` here seems harmless.
2. can't understand why `grab a copy of p->parent`  
  `p->parent` could its origin parent or initproc,  
  so before accessing it we should lock p.
3. `p`(i.e. child) set its state to `ZOMBIE` then release parent's lock  
  + `parent` is waken, but it cannot be scheduled before `child` release parent's lock
  + `parent` might be executing `wait`, but it not check if its children's states are `ZOMBIE` before  
    the exiting `child` calls `sched` and then `scheduler thread` release `child`'s lock

## lec12 - File systems

### what happen after $ echo hi > x ?
1.  sh encounters x, then call `open`(system call, corresponds to `sys_open`).
2.  -- `sys_open`(*sysfile.c:301*) calls `create` to create an inode for file x.
3.  ---- `create`(*sysfile.c:261*) calls `ialloc` to allocate an inode.
4.  ---- `create`(*sysfile.c:278*) calls `dirlink` write diretory entry for x.
5.  -- `sys_open`(*sysfile.c:325*) calls `filealloc`&`fdalloc` to create file and fd for x.
6.  -- `sys_open`(*sysfile.c:325*) return x's fd to relevant user process.
7.  echo uses `write(1, ...)`, sh uses redirection, i.e., `write` is called(corresponds to `sys_write`).
8.  -- `sys_write`(*sysfile.c:91*) calls `filewrite` to write hi into the open file for x.
9.  ---- `filewrite`(*file.c:164*) calls `writei` to write hi into the inode for x.
10. ------ `writei`(*fs.c:498-505*) calls `bread`, `log_write`&`brelse` to write hi into the block for x.
11. -------- `writei`(*fs.c:498*) calls `bmap` for block address, which may call `balloc` to alloc new block.
12. ------ `writei`(*fs.c:514*) calls `iupdate` to update inode's content to disk.

### what is in block 32, what is inode 0 used for ?
sizeof(dinode) = 64B, BSIZE = 1024B, thus 16 inode per block.  
xv6-riscv requires NINODES=200, thus 13 blocks are needed, i.e., block 32~44.  

[just for reservation](https://stackoverflow.com/questions/2099121/why-do-inode-numbers-start-from-1-and-not-0)


### bitmap block content
see `bmap`&`balloc`

## lec13 - Crash Recovery

### commit point
from lec note:
```
the "n" value in the log header on disk indicates commit
  non-zero == commited, ...
  zero == not commited, ...
  write of non-zero "n" is the "commit point"
```

from code(see *log.c:107~110* and subsequent `bwrite`):
```
hb->n = log.lh.n;
// here might be confusing, see note below
for (i = 0; i < log.lh.n; i++) {
  hb->block[i] = log.lh.block[i];
}
```
note: code here writing log header's n and blocks to install,  
is actually atomic, because hb(buf->data) is just a buffer cache,  
`bwrite` actually performs the atomic write to the log header block, so don't worry.

### re-do log
just as the lec note wrote:  
it is OK to replay the log more than twice.

### performance job
1. can wrap multiple system call into a single transaction.
2. write absorbtion in logging. 
3. (bad) data disk blocks are written twice(one is log, the other is home).

see the bottom of lec note for more. 