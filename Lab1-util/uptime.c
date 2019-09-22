#include "kernel/types.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
    uint64 ticks;

    if (argc != 1)
    {
        printf("usege: uptime\n");
        exit();
    }

    ticks = uptime();
    printf("%l\n", ticks);

    exit();
}