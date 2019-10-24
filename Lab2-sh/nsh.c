/* Lab sh, features include:
    program exec - done
    IO redirection - done
    pipe
    many programs
*/

#include "kernel/types.h"
#include "kernel/fcntl.h"
#include "user/user.h"

#define MAXLINE 100
#define MAXWORD 20
#define MAXARGS 10

struct cmd
{
    char prog[MAXWORD];
    char *argv[MAXARGS];
    char *in;
    char *out;
};

int getcmd(char *buf, int nbuf);
void parsecmd(struct cmd *cmd, char *buf, int nbuf);
void runcmd(struct cmd *cmd);

int
main(void)
{
    static char cmdline[MAXLINE];
    struct cmd cmd;

    while (getcmd(cmdline, sizeof(cmdline)) >= 0)
    {
        cmdline[strlen(cmdline)-1] = 0;
        parsecmd(&cmd, cmdline, sizeof(cmdline));
        if (fork() == 0)
            runcmd(&cmd);
        wait(0);
    }

    // getcmd receive error or exit
    exit(0);
}

int getcmd(char *buf, int nbuf)
{
    printf("@");
    memset(buf, 0, nbuf);
    gets(buf, nbuf);

    if (buf[0] == 0)
        return -1;
    return 0;
}

void
parsecmd(struct cmd *cmd, char *buf, int nbuf)
{
    int i, j, argvi, maxi;
    char errorbuf[MAXLINE];

    i = 0;
    argvi = 1;
    maxi = strlen(buf);
    strcpy(errorbuf, buf);

    // init cmd
    cmd->prog[0] = 0;
    cmd->argv[1] = 0;
    cmd->in = 0;
    cmd->out = 0;

    // get prog name
    while (i < maxi && buf[i] != ' ')
        i++;
    if (i > MAXWORD - 1)
    {
        fprintf(2, "nsh error: prog name too long(%s)\n", errorbuf);
        exit(-1);
    }
    buf[i++] = 0;
    strcpy(cmd->prog, buf);
    cmd->argv[0] = buf;

    // get argv
    if (i >= maxi)
        return;
    while (1)
    {
        while (i < maxi && buf[i] == ' ')
            i++;
        if (i >= maxi || buf[i] == '<' || buf[i] == '>')
            break;
        if (argvi >= MAXARGS - 1)
        {
            fprintf(2, "nsh error: too many args(%s)\n", errorbuf);
            exit(-1);
        }
        cmd->argv[argvi++] = buf + i;
        while (i < maxi && buf[i] != ' ')
            i++;
        if (i < maxi)
            buf[i++] = 0;
    }
    cmd->argv[argvi] = 0;

    // get io redirection
    if (i >= maxi)
        return;
    j = i + 1;
    while (j < maxi && buf[j] == ' ')
        j++;
    if (j >= maxi)
    {
        fprintf(2, "nsh error: no specified file for io redirection(%s)", errorbuf);
        exit(-1);
    }
    if (buf[i] == '<')
        cmd->in = buf + j;
    else if (buf[i] == '>')
        cmd->out = buf + j;
    else
    {
        // control  never reach here
        fprintf(2, "nsh error: io redirection error(%s)", errorbuf);
        exit(-1);
    }

    while (j < maxi && buf[j] != ' ')
        j++;
    if (j >= maxi)
        return;
    buf[j] = 0;
    i = j + 1;

    while (i < maxi && buf[i] == ' ')
        i++;
    if (i >= maxi)
        return;
    if (buf[i] != '<' && buf[i] != '>')
    {
        fprintf(2, "nsh error: io redirection error(%s)", errorbuf);
        exit(-1);
    }
    if (buf[i] == '<' && cmd->in)
    {
        fprintf(2, "nsh error: too many i redirection(%s)", errorbuf);
        exit(-1);
    }
    if (buf[i] == '>' && cmd->out)
    {
        fprintf(2, "nsh error: too many o redirection(%s)", errorbuf);
        exit(-1);
    }
    j = i + 1;
    while (j < maxi && buf[j] == ' ')
        j++;
    if (j >= maxi)
    {
        fprintf(2, "nsh error: no specified file for io redirection(%s)", errorbuf);
        exit(-1);
    }
    if (buf[i] == '<')
        cmd->in = buf + j;
    else if (buf[i] == '>')
        cmd->out = buf + j;
    else
    {
        // control  never reach here
        fprintf(2, "nsh error: io redirection error(%s)", errorbuf);
        exit(-1);
    }
    while (j < maxi && buf[j] != ' ')
        j++;
    if (j >= maxi)
        return;
    buf[j] = 0;
    return;
}

void
runcmd(struct cmd *cmd)
{
    if (cmd->in)
    {
        close(0);
        if(open(cmd->in, O_RDONLY)<0)
        {
            fprintf(2, "nsh error: cannot read file %s\n", cmd->in);
            exit(-1);
        }
    }
    if (cmd->out)
    {
        close(1);
        if(open(cmd->out, O_WRONLY | O_CREATE)<0)
        {
            fprintf(2, "nsh error: cannot write or create file %s\n", cmd->out);
            exit(-1);
        }
    }

    exec(cmd->prog, cmd->argv);

    fprintf(2, "nsh error: exec failed\n");
    exit(-1);
}