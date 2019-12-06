#include "resource.h"

#define NPROC 20
#define LINE 20

enum procstate
{
    READY,
    RUNNING,
    BLOCKED,
    SUSPENDED,                  // not used yet
    UNUSED
};

struct proc
{
    enum procstate state;
    struct proc *parent;        // not used yet
    struct proc_list *child;    // not used yet
    struct resc_list *resc;
    struct resc_list *req;

    int priority;
    char name[16];
    unsigned int pid;
};

struct proc_list
{
    struct proc *proc;
    struct proc_list *next_proc;
};

struct resc_list
{
    struct resource *resource;
    struct resc_list *next_resource;
};

struct ready_proc
{
    struct proc *proc;
};

struct block_list
{
    struct proc *proc;
    struct block_list *next_proc;
};