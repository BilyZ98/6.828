#include "cmd.h"
#include "proc.h"
#include "defs.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int getcmd(char *buf, int size)
{
    int i;

    printf("> ");
    memset(buf, 0, size);
    fgets(buf, size, stdin);

    if (buf[0] == 0)
        return -1;

    i = 0;
    while (buf[i] != '\n')
        i++;
    buf[i] = '\0';
    return 0;
}

void parsecmd(char *buf, int size, struct cmd *cmd)
{
    int start, i = 0;

    // cmd type
    while (buf[i] != '\0' && buf[i] != ' ')
        i++;
    buf[i++] = '\0';

    if (!strcmp(buf, "create"))
    {
        cmd->type = CREATE;

        // get proc name
        start = i;
        while (buf[i] != '\0' && buf[i] != ' ')
            i++;
        buf[i++] = '\0';
        strcpy(cmd->proc_name, buf + start);

        // get priority
        start = i;
        while (buf[i] != '\0' && buf[i] != ' ')
            i++;
        buf[i++] = '\0';
        cmd->priority = atoi(buf + start);
    }
    else if (!strcmp(buf, "show"))
    {
        cmd->type = SHOW;

        // check proc or resc
        start = i;
        while (buf[i] != '\0' && buf[i] != ' ')
            i++;
        buf[i++] = '\0';

        cmd->pid = cmd->rid = -1;
        if(!strcmp(buf+start, "proc"))
            cmd->pid = 0;
        else if(!strcmp(buf+start, "resc"))
            cmd->rid = 0;
        else
            cmd->pid = cmd->rid = 0;
    }
    else if (!strcmp(buf, "run"))
        cmd->type = RUN;
    else if (!strcmp(buf, "finish"))
        cmd->type = FINISH;
    else if (!strcmp(buf, "request"))
    {
        cmd->type = REQUEST;

        // get proc id
        start = i;
        while (buf[i] != '\0' && buf[i] != ' ')
            i++;
        buf[i++] = '\0';
        cmd->pid = atoi(buf + start);

        // get resource id
        start = i;
        while (buf[i] != '\0' && buf[i] != ' ')
            i++;
        buf[i++] = '\0';
        cmd->rid = atoi(buf + start);
    }
    else if(!strcmp(buf, "timeout"))
        cmd->type = TIMEOUT;
    else if(!strcmp(buf, "activate"))
        cmd->type = ACTIVATE;
}

void runcmd(struct cmd *cmd)
{
    struct proc *p;

    if (cmd->type == ERROR)
    {
        printf("command error!\n");
        return;
    }
    else if (cmd->type == CREATE)
    {
        if (cmd->priority < 0)
        {
            printf("priority less than 0!\n");
            return;
        }

        if ((p = create_proc()) == 0)
        {
            printf("process num exceed!\n");
            return;
        }

        p->priority = cmd->priority;
        strcpy(p->name, cmd->proc_name);
        push_ready(p);
    }
    else if (cmd->type == SHOW)
    {
        if(cmd->pid == 0)
            show_procs();
        if(cmd->rid == 0)
            show_rescs();
    }
    else if (cmd->type == RUN)
        run_proc();
    else if (cmd->type == FINISH)
        fin_proc();
    else if (cmd->type == REQUEST)
    {
        if (cmd->pid < 0 || cmd->pid >= NPROC || cmd->rid < 0 || cmd->rid >= NRESOURCE)
            printf("pid or rid not valid!\n");
        else
            request(cmd->pid, cmd->rid);
    }
    else if(cmd->type == TIMEOUT)
        timeout();
    else if(cmd->type == ACTIVATE)
        activate();
}

// only for debug
void printcmd(struct cmd *cmd)
{
    printf("type: %d\n", cmd->type);
    printf("proc_name: %s\n", cmd->proc_name);
    printf("priority: %d\n", cmd->priority);
    printf("rid: %d\n", cmd->rid);
}