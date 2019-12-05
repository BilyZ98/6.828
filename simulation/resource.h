#ifndef _RESOURCE_
#define _RESOURCE_

enum rstate
{
    FREE,
    USED
};

struct resource
{
    unsigned int rid;
    enum rstate state;
};

#endif