#ifndef _RESOURCE_
#define _RESOURCE_

#define NRESOURCE 20

enum rstate
{
    FREE,
    USED
};

struct resource
{
    enum rstate state;
    unsigned int rid;
    unsigned int pid;
};

#endif