#include "resource.h"
#include "proc.h"
#include "defs.h"
#include "stdio.h"
#include <stdlib.h>

extern struct proc proc[];

static struct resource resource[NRESOURCE];

void init_resources()
{
    int i;

    for (i = 0; i < NRESOURCE; i++)
    {
        resource[i].state = FREE;
        resource[i].rid = i;
        resource[i].pid = -1;
    }
}

// request resource
void request(int pid, int rid)
{
    struct proc *p = &proc[pid];
    struct resource *r = &resource[rid];

    if (p->state != RUNNING)
    {
        if (p->state == UNUSED)
            printf("process %d not valid!\n", p->pid);
        else
            printf("process %d is not running!\n", p->pid);
        return;
    }

    if (r->state == USED)
    {
        printf("this request blocks\n");
        printf("resource %d is being used by process %d\n", r->rid, r->pid);
        push_req(p->pid, r->rid);
        push_block(p->pid);
        return;
    }

    // resource is free
    push_resc(p->pid, r->rid);
}

// request all resource for a single proc
void requests(int pid)
{
    struct proc *p = &proc[pid];
    struct resc_list *rl;

    while(p->req)
    {
        if(p->req->resource->state == USED)
        {
            push_block(pid);
            return;
        }

        request(pid, p->req->resource->rid);
        rl = p->req;
        p->req = p->req->next_resource;
        free(rl);
    }
}

void push_req(int pid, int rid)
{
    struct proc *p = &proc[pid];
    struct resc_list *rl = (struct resc_list *)malloc(sizeof(struct resc_list));

    if (rl == 0)
        panic("push_req out of memory!\n");

    rl->resource = &resource[rid];
    rl->next_resource = p->req;
    p->req = rl;
}

void push_resc(int pid, int rid)
{
    struct proc *p = &proc[pid];
    struct resc_list *rl = (struct resc_list *)malloc(sizeof(struct resc_list));

    if (rl == 0)
        panic("push_resc out of memory!\n");

    rl->resource = &resource[rid];
    rl->next_resource = p->resc;
    p->resc = rl;
    resource[rid].state = USED;
    resource[rid].pid = pid;
}

// show resource
void show_rescs()
{
    int i;

    printf("资源RESOURCE:\n");
    for (i = 0; i < NRESOURCE; i++)
    {
        printf("rid: %d, ", i);
        if(resource[i].state == FREE)
            printf("state: %s\n", "FREE");
        else
            printf("state: %s, pid: %d\n", "USED", resource[i].pid);
    }
}