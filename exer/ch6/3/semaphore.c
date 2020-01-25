// Semaphore implementation
// more reference: Dijkstra's papar <<Cooperating sequential processes>>

#include "types.h"
#include "param.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "semaphore.h"
#include "defs.h"

void
sem_init(struct semaphore *sem, char *name, int count)
{
    initlock(&sem->lock, "semaphore lock");
    sem->count = count;
    sem->name = name;
    sem->pid = 0;
}

// P operation
void
sem_wait(struct semaphore *sem)
{
    while(1) {
        acquire(&sem->lock);
        if(sem->count != 0)
            break;
        release(&sem->lock);
    }
    sem->count -= 1;
    sem->pid = myproc()->pid;
    release(&sem->lock);
}

// V operation
void
sem_post(struct semaphore *sem)
{
    acquire(&sem->lock);
    sem->count += 1;
    sem->pid = 0;
    release(&sem->lock);
}

// test if current proc holding
// only useful in binary semaphore
int
sem_holding(struct semaphore *sem)
{
    int r;

    acquire(&sem->lock);
    r = !sem->count && (sem->pid == myproc()->pid);
    release(&sem->lock);
    return r;
}