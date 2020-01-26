#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "date.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
  int n;
  if(argint(0, &n) < 0)
    return -1;
  exit(n);
  return 0;  // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  if(argaddr(0, &p) < 0)
    return -1;
  return wait(p);
}

uint64
sys_sbrk(void)
{
  int addr;
  int n;

  if(argint(0, &n) < 0)
    return -1;
  addr = myproc()->sz;
  if(growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  if(argint(0, &pid) < 0)
    return -1;
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

uint64
sys_sigalarm(void)
{
  int tick0;
  uint64 handler;
  struct proc *p = myproc();

  if(argint(0, &tick0) < 0 || argaddr(1, &handler) < 0)
    return -1;
  if(tick0 == 0){
    p->hassignal = 0;
    return 0;
  }
  p->hassignal = 1;
  p->insignal = 0;
  p->tick0 = tick0;
  p->ticks = 0;
  p->handler = handler;
  return 0;
}

uint64
sys_sigreturn(void)
{
  struct proc *p = myproc();

  p->insignal = 0;
  p->ticks = 0;

  p->tf->ra = p->sigtext.ra;
  p->tf->sp = p->sigtext.sp;
  p->tf->t0 = p->sigtext.t0;
  p->tf->t1 = p->sigtext.t1;
  p->tf->t2 = p->sigtext.t2;
  p->tf->a0 = p->sigtext.a0;
  p->tf->a1 = p->sigtext.a1;
  p->tf->a2 = p->sigtext.a2;
  p->tf->a3 = p->sigtext.a3;
  p->tf->a4 = p->sigtext.a4;
  p->tf->a5 = p->sigtext.a5;
  p->tf->a6 = p->sigtext.a6;
  p->tf->a7 = p->sigtext.a7;
  p->tf->t3 = p->sigtext.t3;
  p->tf->t4 = p->sigtext.t4;
  p->tf->t5 = p->sigtext.t5;
  p->tf->t6 = p->sigtext.t6;

  p->tf->s0 = p->sigtext.s0;
  p->tf->s1 = p->sigtext.s1;
  p->tf->s2 = p->sigtext.s2;
  p->tf->s3 = p->sigtext.s3;
  p->tf->s4 = p->sigtext.s4;
  p->tf->s5 = p->sigtext.s5;
  p->tf->s6 = p->sigtext.s6;
  p->tf->s7 = p->sigtext.s7;
  p->tf->s8 = p->sigtext.s8;
  p->tf->s9 = p->sigtext.s9;
  p->tf->s10 = p->sigtext.s10;
  p->tf->s11 = p->sigtext.s11;

  p->tf->epc = p->handret;

  return p->tf->a0;
}
