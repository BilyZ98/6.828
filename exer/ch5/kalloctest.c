#include "kernel/types.h"
#include "kernel/riscv.h"
#include "user/user.h"

// Test xv6-riscv kalloc function
// comment out acquire & release in kalloc func
// then test.
// error 1: usertrap(): unexpected...
// error 2: expect 1 but find 2/0

#define MEMNUM 200
#define CNT 2000

unsigned long randstate;
unsigned int
rand()
{
    randstate = randstate * 1664525 + 1013904223;
    return randstate;
}

int main()
{
    char *mem[MEMNUM], leak;
    int i, c;
    int pid, master_pid;

    master_pid = getpid();

    for (c = 1; c <= CNT; c++)
    {
        pid = fork();

        if (pid < 0)
        {
            printf("kalloctest: fork fail\n");
            exit(-1);
        }

        if (pid == 0)
        {
            randstate = 1;
            for (i = 0; i < MEMNUM; i++)
                mem[i] = (char *)malloc(PGSIZE);
            for (i = 0; i < MEMNUM; i++)
                memset(mem[i], 1, PGSIZE);
            for (i = 0; i < MEMNUM; i++)
            {
                leak = *(char *)mem[i];
                free(mem[i]);
                if (leak != 1)
                {
                    printf("kalloctest: page realloc, expect %d but find %d\n", 1, leak);
                    kill(master_pid);
                    exit(-1);
                }
            }
            exit(0);
        }
        else
        {
            randstate = 2;
            for (i = 0; i < MEMNUM; i++)
                mem[i] = (char *)malloc(PGSIZE);
            for (i = 0; i < MEMNUM; i++)
                memset(mem[i], 2, PGSIZE);
            for (i = 0; i < MEMNUM; i++)
            {
                leak = *(char *)mem[i];
                free(mem[i]);
                if (leak != 2)
                {
                    printf("kalloctest: page realloc, expect %d but find %d\n", 2, leak);
                    kill(pid);
                    exit(-1);
                }
            }
        }

        if(wait(0) != pid){
            printf("kalloctest: wait pid %d error\n", pid);
            exit(-1);
        }
    }

    printf("kalloctest OK\n");
    exit(0);
}