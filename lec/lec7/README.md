## traps in xv6
1. system call: ecall
2. exceptions: illegal instruction
3. interrupt: device
4. (timer interrupt)

## sec2
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

## sec3
!important: `ecall` => In trampoline.S: supervisor mode with no kernel page table.  
Without `ecall`, although user process can access kernel page from p->tf,  
it cannot use csr instruction to change `satp`.

## sec8
how does the kernel initialize `console` or how does `open("console")` work in *init.c*?  
how `read` system call make their way through the kernel to `consoleread`?

## sec9
```
However, the need for kernel code to be mindful that it might be suspended (due to
a timer interrupt) and later resume on a different CPU is the source of some complexity in xv6.
The kernel could be made somewhat simpler if device and timer interrupts only occurred while
executing user code.
```

## ch4 exercises, possible method
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