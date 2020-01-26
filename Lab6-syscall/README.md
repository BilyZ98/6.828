# Lab6-syscall: user-level threads and alarm

## uthread
easy, just copy *swtch.S*  
more:  
[http://homepage.cs.uiowa.edu/~jones/opsys/threads/](http://homepage.cs.uiowa.edu/~jones/opsys/threads/)  
[https://www.cs.utexas.edu/users/dahlin/Classes/UGOS/labs/labULT/proj-ULT.html](https://www.cs.utexas.edu/users/dahlin/Classes/UGOS/labs/labULT/proj-ULT.html)

## alarm
Q: how to save registers and switch them?  
A: save caller-save registers.

tricky switching:
```
  2e:	55c080e7          	jalr	1372(ra) # 586 <sigreturn>
}
  // after sigreturn(system call), instructions below will never be executed
  32:	60a2                	ld	ra,8(sp)
  34:	6402                	ld	s0,0(sp)
  36:	0141                	addi	sp,sp,16
  38:	8082                	ret
```
note:  
1. storing the value of ra is tricky.
2. called-saved needed too because of the assembly code above.

so many registers need to be stored, close to trapframe.
