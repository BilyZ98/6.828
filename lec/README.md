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