#include "defs.h"
#include "cmd.h"
#include "proc.h"
#include <string.h>
#include <stdio.h>

#define MAXLINE 100

int main()
{
    static char cmdline[MAXLINE];
    static struct cmd cmd;

    init_resources();
    init_procs();
    while(getcmd(cmdline, sizeof(cmdline)) >= 0)
    {
        cmd.type = ERROR;
        parsecmd(cmdline, sizeof(cmdline), &cmd);
        runcmd(&cmd);
    }
}

void panic(char *s)
{
    printf("%s", s);
    for(;;)
        ;
}