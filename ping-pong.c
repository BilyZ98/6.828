#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/types.h>

int main(int argc, char *argv[])
{
    int times;
    int pipes[2][2];
    time_t start, end;

    if (argc != 2 || (times = atoi(argv[1])) <= 0)
    {
        fprintf(stderr, "usage: ./ping-pong [times a byte transmitted in a pipe]\n");
        exit(0);
    }

    if (pipe(pipes[0]) < 0 || pipe(pipes[1]) < 0)
    {
        fprintf(stderr, "Error occur when creating pipes!\n");
        exit(0);
    }

    start = time(NULL);
    if (fork() == 0)
    {
        /* child 1 */
        close(0);
        dup(pipes[0][0]);
        close(1);
        dup(pipes[1][1]);
        close(pipes[0][1]);
        close(pipes[1][0]);

        char buf[2] = {'a', 'b'};
        while (times)
        {
            if (write(1, buf, 1) < 0)
            {
                fprintf(stderr, "child 1: write error!\n");
                exit(0);
            }
            if (read(0, buf, 1) < 0)
            {
                fprintf(stderr, "child 1: read error!\n");
                exit(0);
            }
            times--;
        }
    }
    if (fork() == 0)
    {
        /* child 2 */
        close(0);
        dup(pipes[1][0]);
        close(1);
        dup(pipes[0][1]);
        close(pipes[0][0]);
        close(pipes[1][1]);

        int rc;
        char buf[2];
        while ((rc = read(0, buf, 1)) > 0)
            if (write(1, buf, 1) < 0)
            {
                fprintf(stderr, "child 2: write error!\n");
                exit(0);
            }

        exit(0);
    }
    close(pipes[0][0]);
    close(pipes[0][1]);
    close(pipes[1][0]);
    close(pipes[1][1]);
    wait(NULL);

    end = time(NULL);
    printf("Time spent on %d bytes: %us\n", times, (unsigned int)(end-start));
    return 0;
}