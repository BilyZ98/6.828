/* Lab sh, features include:
    program exec - done
    IO redirection - done
    pipe - done
    many programs - done
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
int splitcmd(char *buf, int nbuf);
void parsecmd(struct cmd *cmd, char *buf, int nbuf);
void runcmd(struct cmd *cmd);

int main(void)
{
  int i, children;
  int cmdi, nexti;
  int fds[2], prevfds[2];
  static char cmdline[MAXLINE];
  struct cmd cmd;

  while (getcmd(cmdline, sizeof(cmdline)) >= 0)
  {
    children = 0;
    cmdi = nexti = 0;
    cmdline[strlen(cmdline) - 1] = 0;

    while (1)
    {
      cmdi = nexti;
      prevfds[0] = fds[0];
      prevfds[1] = fds[1];
      nexti = splitcmd(cmdline+cmdi, strlen(cmdline+cmdi));
      
      // debug
      // fprintf(2, "cmdi: %d, nexti: %d\n", cmdi, nexti);

      if(nexti >= 0)
        pipe(fds);
      parsecmd(&cmd, cmdline+cmdi, strlen(cmdline+cmdi));
      if (fork() == 0)
      {
        if(cmdi != 0)
        {
          close(0);
          dup(prevfds[0]);
        }
        if(nexti >= 0)
        {
          close(1);
          dup(fds[1]);
          close(fds[0]);
        }
        runcmd(&cmd);
      }
      children++;
      if(cmdi != 0)
        close(prevfds[0]);
      if(nexti >= 0)
        close(fds[1]);
      else
        break;
    }
    for(i = 1;i <= children; i++)
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

int splitcmd(char *buf, int nbuf)
{
  int i;

  for(i = 0;i < nbuf;i++)
    if(buf[i] == '|')
    {
      buf[i] = 0;
      return i+1;
    }
  return -1;
}

void parsecmd(struct cmd *cmd, char *buf, int nbuf)
{
  // debug
  // fprintf(2, "parse cmd: %s, len: %d\n", buf, nbuf);

  int i, j, argvi, maxi, progi;
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

  // clear space in front of real cmd
  while (i < maxi && buf[i] == ' ')
    i++;
  if(i>= maxi)
  {
    fprintf(2, "nsh error: only space in the cmd\n");
    exit(-1);
  }
  progi = i;

  // get prog name
  while (i < maxi && buf[i] != ' ')
    i++;
  if (i > MAXWORD - 1)
  {
    fprintf(2, "nsh error: prog name too long(%s)\n", errorbuf);
    exit(-1);
  }
  buf[i++] = 0;
  strcpy(cmd->prog, buf + progi);
  cmd->argv[0] = buf + progi;

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

void runcmd(struct cmd *cmd)
{
  if (cmd->in)
  {
    close(0);
    if (open(cmd->in, O_RDONLY) < 0)
    {
      fprintf(2, "nsh error: cannot read file %s\n", cmd->in);
      exit(-1);
    }
  }
  if (cmd->out)
  {
    close(1);
    if (open(cmd->out, O_WRONLY | O_CREATE) < 0)
    {
      fprintf(2, "nsh error: cannot write or create file %s\n", cmd->out);
      exit(-1);
    }
  }

  exec(cmd->prog, cmd->argv);

  fprintf(2, "nsh error: exec failed\nprog: %s\n", cmd->prog);
  exit(-1);
}