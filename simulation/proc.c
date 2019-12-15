#include "proc.h"
#include "defs.h"
#include "resource.h"
#include <stdio.h>
#include <stdlib.h>

struct proc proc[NPROC];
static int irunning;

static struct ready_proc ready_list[NPROC + 1];
static int ready_head;
static int ready_tail;

static struct block_list *block_list;

void init_procs()
{
    int i;

    for (i = 0; i < NPROC; i++)
    {
        proc[i].state = UNUSED;
        proc[i].pid = i;
        proc[i].priority = 0;
        proc[i].resc = 0;
        proc[i].req = 0;
    }

    irunning = -1;
    ready_head = ready_tail = 0;
    block_list = 0;
}

struct proc *create_proc()
{
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    {
        if (p->state == UNUSED)
            goto FOUND;
    }
    return 0;

FOUND:
    if (p->resc || p->req)
        panic("previous proc's resource not free!");
    p->state = READY;
    return p;
};

void delete_proc(struct proc *p)
{
    p->state = UNUSED;
}

void suspend_proc(struct proc *p)
{
    p->state = SUSPENDED;
}

void wakeup_proc(struct proc *p)
{
    if (p->state == SUSPENDED)
        p->state = READY;
}

void push_ready(struct proc *p)
{
    p->state = READY;
    ready_list[ready_tail].proc = p;
    ready_tail = (ready_tail + 1) % (NPROC + 1);

    if (ready_tail == ready_head)
        panic("ready list's num of proc exceed!\n");
}

// show all process state
static void show_proc(struct proc *);
void show_procs()
{
    int i;
    struct block_list *bl;

    // show ready list:
    printf("%s:\n", "就绪READY");
    if (ready_head == ready_tail)
        printf("none\n");
    else
        for (i = ready_head; i != ready_tail; i = (i + 1) % (NPROC + 1))
            show_proc(ready_list[i].proc);
    printf("\n");

    // show running proc
    printf("%s:\n", "运行RUNNING");
    if (irunning >= 0)
        show_proc(&proc[irunning]);
    else
        printf("none\n");
    printf("\n");

    // show blocked procs
    printf("%s:\n", "阻塞BLOCKED");
    if (block_list)
        for (bl = block_list; bl; bl = bl->next_proc)
            show_proc(bl->proc);
    else
        printf("none\n");
    printf("\n");
}

static void show_proc(struct proc *p)
{
    struct resc_list *rl;

    printf("%s, ", p->name);
    printf("pid: %d, ", p->pid);
    printf("priority: %d", p->priority);
    if (p->resc)
    {
        printf(", resource: (");
        rl = p->resc;
        printf("%d", rl->resource->rid);
        while ((rl = rl->next_resource))
            printf(",%d", rl->resource->rid);
        printf(")");
    }
    if (p->req)
    {
        printf(", request: (");
        rl = p->req;
        printf("%d", rl->resource->rid);
        while ((rl = rl->next_resource))
            printf(",%d", rl->resource->rid);
        printf(")");
    }
    printf("\n");
}

// run process
void run_proc()
{
    struct proc *p;
    int i, j, priority;

    if (irunning >= 0)
    {
        p = &proc[irunning];
        printf("process %s already running.\n", p->name);
        return;
    }

    if (ready_head == ready_tail)
    {
        printf("no process can run.\n");
        return;
    }

    // fixed-priority pre-emptive scheduling
    j = ready_head;
    priority = ready_list[ready_head].proc->priority;
    for (i = ready_head; i != ready_tail; i = (i + 1) % (NPROC + 1))
    {
        if (ready_list[i].proc->priority > priority)
        {
            priority = ready_list[i].proc->priority;
            j = i;
        }
    }
    p = ready_list[j].proc;
    for (i = j; i != ready_head; i = j)
    {
        j = (i - 1 < 0) ? (i + NPROC) : (i - 1); // j = (i-1)%(NPROC+1)
        ready_list[i].proc = ready_list[j].proc;
    }
    ready_head = (ready_head + 1) % (NPROC + 1);
    p->state = RUNNING;
    irunning = p->pid;

    if (p->req)
        requests(p->pid);
}

// finish process
static void free_resc(struct resc_list *);
void fin_proc()
{
    struct proc *p;
    struct resc_list *rl;

    if (irunning < 0)
    {
        printf("no process is running.");
        return;
    }

    p = &proc[irunning];
    if (p->req)
    {
        printf("cannot finish process %s\n", p->name);
        rl = p->req;
        printf("it requests resource: %d", rl->resource->rid);
        rl->resource->state = FREE;
        while ((rl = rl->next_resource))
        {
            printf(", %d", rl->resource->rid);
            rl->resource->state = FREE;
        }
        printf("\n");
        return;
    }
    printf("process %s finished\n", p->name);
    free_resc(p->resc);
    p->resc = 0;
    p->state = UNUSED;
    irunning = -1;
}

static void free_resc(struct resc_list *rl)
{
    struct resc_list *prev_rl;

    if (!rl)
        return;

    printf("freeing resource:\n");
    while (rl)
    {
        printf("rid: %d\n", rl->resource->rid);
        rl->resource->state = FREE;
        prev_rl = rl;
        rl = rl->next_resource;
        free(prev_rl);
    }
}

// block list action

void push_block(int pid)
{
    struct block_list *bl;
    struct proc *p;

    if (pid < 0 || pid >= NPROC)
        panic("push_block: pid wrong!\n");

    if (pid != irunning)
    {
        printf("process %d is not running, thus cannot blocks", pid);
        return;
    }

    p = &proc[pid];
    p->state = BLOCKED;
    irunning = -1;
    if (block_list)
    {
        bl = (struct block_list *)malloc(sizeof(struct block_list));
        if (!bl)
            panic("push_block: run out of memory!\n");
        bl->proc = p;
        bl->next_proc = block_list;
        block_list = bl;
    }
    else
    {
        block_list = (struct block_list *)malloc(sizeof(struct block_list));
        if (!block_list)
            panic("push_block: run out of memory!\n");
        block_list->proc = p;
        block_list->next_proc = 0;
    }
}

struct block_list *delete_block(struct block_list *prev_bl, struct block_list *bl)
{
    struct block_list *next_bl;

    // prev_bl == 0 means bl == block_list
    push_ready(bl->proc);
    next_bl = bl->next_proc;
    if (prev_bl)
        prev_bl->next_proc = next_bl;
    else
        block_list = bl->next_proc;
    free(bl);

    return next_bl;
}

// timeout event

void timeout()
{
    if (irunning < 0)
        return;

    push_block(irunning);
    irunning = -1;
}

// activate event

void activate()
{
    int actflag;
    struct proc *p;
    struct resc_list *rl;
    struct block_list *bl, *prev_bl;

    prev_bl = 0;
    bl = block_list;
    while (bl)
    {
        actflag = 1;
        p = bl->proc;
        if (p->req)
        {
            rl = p->req;
            do
            {
                if (rl->resource->state == USED)
                {
                    actflag = 0;
                    break;
                }
            } while ((rl = rl->next_resource));
        }

        // actflag == 1 means it can be unblocked
        if (actflag)
            bl = delete_block(prev_bl, bl);
        else
        {
            prev_bl = bl;
            bl = bl->next_proc;
        }
    }
}