# Homework: boot xv6
## Goal
figure out the mechanism of boot loader,  
that is, how to enter kernel  
P.S. ***kernel*** here means exactly the executable file named *kernel* or *xv6-public/kernel*
## xv6-public/kernel
from kernel.asm we see:
![](./img/2019-10-03-20-34-07.png)
now we know the entry of kernel is 0x8010000c
## bootblock.asm
here we can view the assembly code of bootasm.S and bootmain.c  
bootasm start at 0x7c00  
bootmain start at 0x7d3b
## bootasm.S
1. after reading xv6-book appendix B: the boot loader and comment in the top of bootasm.S, 
we know we can start our analysis at 0x7c00
2. that is, after `$ make qemu-gdb` and `$ gdb`,
we can break at 0x7c00:
```
(gdb) break *0x7c00
(gdb) continue
```
3. next we watch changes of the stack and %esp
4. use `(gdb) stepi` or just read bootasm.S, we can have:
```
7c43:       bc 00 7c 00 00          mov    $0x7c00,%esp
7c48:       e8 ee 00 00 00          call   7d3b <bootmain>
```
5. after these two instructions, we have %esp=0x7bfc and word 0x7c4d there in memory:
```
(gdb) print /x $esp
$4 = 0x7bfc
(gdb) x/w $esp
0x7bfc:	0x00007c4d
```
6. enter bootmain
  
note:  
0x7c00 up is the code of boot loader  
0x7c00 down is the stack it uses
## bootmain.c
1. use gdb to find entry():
```
(gdb) break *0x7d87
(gdb) continue
7d87:       ff 15 18 00 01 00       call   *0x10018
7d8d:       eb d5                   jmp    7d64 <bootmain+0x29>
```
2. check the value of *0x10018:
```
(gdb) x/w 0x10018
0x10018:	0x0010000c
```
3. finally we reach the entry of kernel
4. once we enter the kernel, we check the stack:
```
(gdb) break *0x0010000c
(gdb) continue
=> 0x10000c:	mov    %cr4,%eax
(gdb) x/24w $esp
```
![](./img/2019-10-03-21-14-57.png)
$esp = 0x7bdc, valid value in stack:  
0x7dbc: 0x00007d8d // returned ip of kernel entry, caused by `7d87:       ff 15 18 00 01 00       call   *0x10018` in bootmain.c  
0x7bfc: 0x00007c4d // returned ip of bootmain, caused by `7c48:       e8 ee 00 00 00          call   7d3b <bootmain>` in bootasm.S  
5. homework done