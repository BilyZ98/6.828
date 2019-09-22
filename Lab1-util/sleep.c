#include "kernel/types.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
    int secs, rc;

    if (argc != 2)
    {
        printf("usege: sleep [SECS]\n");
        exit();
    }

    secs = atoi(argv[1]);
    rc = sleep(secs);
    if (rc < 0)
        printf("error: sleep return neg\n");
    exit();
}