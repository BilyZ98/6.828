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
    while(buf[i] != '\n')
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

    if(!strcmp(buf, "create"))
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
    else if(!strcmp(buf, "show"))
        cmd->type = SHOW;
    else if(!strcmp(buf, "run"))
        cmd->type = RUN;
    else if(!strcmp(buf, "finish"))
        cmd->type = FINISH;
}

void runcmd(struct cmd *cmd)
{
    struct proc *p;

    if(cmd->type == ERROR)
    {
        printf("command error!\n");
        return;
    }
    else if(cmd->type == CREATE)
    {
        if(cmd->priority <= 0)
        {
            printf("specify priority larger than 0!\n");
            return;
        }

        if((p = create_proc()) == 0)
        {
            printf("process num exceed!\n");
            return;
        }

        p->priority = cmd->priority;
        strcpy(p->name, cmd->proc_name);
        push_ready(p);
    }
    else if(cmd->type == SHOW)
        show_procs();
    else if(cmd->type == RUN)
        run_proc();
    else if(cmd->type == FINISH)
        fin_proc();
}

// only for debug 
void printcmd(struct cmd *cmd)
{
    printf("type: %d\n", cmd->type);
    printf("proc_name: %s\n", cmd->proc_name);
    printf("priority: %d\n", cmd->priority);
    printf("rid: %d\n", cmd->rid);
}