#include "kernel/types.h"
#include "user.h"

void
prime(int fd0);

int
main(int argc, char const *argv[])
{
    int i, n_start, n_end;
    int fd[2];

    if (argc != 1)
    {
        printf("usage: primes\n");
        exit();
    }

    n_start = 2;
    n_end = 35;
    close(0);
    pipe(fd);
    if (fork() == 0)
    {
        close(fd[1]);
        prime(fd[0]);
        exit();
    }
    else
    {
        close(fd[0]);
        printf("prime %d\n", n_start);
        for (i = n_start + 1; i <= n_end; i++)
            if (i%n_start != 0)
                write(fd[1], &i, 4);
        close(fd[1]);
        wait();
        sleep(3);
        close(1);
        exit();
    }

    // control never reach here
    printf("unexpected exit in main!\n");
    exit();
}

void
prime(int fd0)
{
    int i, start;
    int fd[2];

    if (read(fd0, &start, 4) <= 0)
        exit();

    printf("prime %d\n", start);
    pipe(fd);
    if (fork() == 0)
    {
        close(fd0);
        close(fd[1]);
        prime(fd[0]);
        exit();
    }
    else
    {
        close(1);
        close(fd[0]);
        while (read(fd0, &i, 4) > 0)
            if (i % start != 0)
                write(fd[1], &i, 4);
        exit();
    }

    // control never reach here
    printf("error occur in prime!\n");
    exit();
}
