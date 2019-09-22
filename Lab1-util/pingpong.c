#include "kernel/types.h"
#include "user.h"

int
main(int argc, char *argv[])
{
    int rc;
    int parent_fd[2];
    int child_fd[2];
    char buf[5];

    if (argc != 1)
    {
        printf("usege: pingpong\n");
        exit();
    }

    if (pipe(parent_fd) < 0 || pipe(child_fd) < 0)
    {
        printf("error when creating pipes!\n");
        exit();
    }

    if (fork() == 0)
    {
        close(parent_fd[1]);
        close(child_fd[0]);

        rc = read(parent_fd[0], buf, 1);
        if (rc < 0)
        {
            printf("child read error!\n");
            exit();
        }
        printf("%d: received ping\n", getpid());

        buf[0] = 'o';
        rc = write(child_fd[1], buf, 1);
        if (rc < 0)
        {
            printf("child write error!\n");
            exit();
        }

        exit();
    }
    else
    {
        close(child_fd[1]);
        close(parent_fd[0]);

        buf[0] = 'i';
        rc = write(parent_fd[1], buf, 1);
        if (rc < 0)
        {
            printf("parent write error!\n");
            exit();
        }

        rc = read(child_fd[0], buf, 1);
        if (rc < 0)
        {
            printf("parent read error!\n");
            exit();
        }
        printf("%d: received pong\n", getpid());

        exit();
    }

    // control never reach here
    printf("error in control flow\n");
    exit();
}