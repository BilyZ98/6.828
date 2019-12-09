 // interpret execcmd to check interpreter
int
interpret(struct execcmd *ecmd)
{
  int i, fd;
  char *ebuf;
  static char buf[BUFSIZE];

  fd = open(ecmd->argv[0], O_RDONLY);
  if(fd<0)
  {
    fprintf(2, "open %s failed\n", ecmd->argv[0]);
    return 1;
  }

  // check interpreter prompt
  read(fd, buf, 2);
  buf[2] = 0;
  if(strcmp(buf, "#!"))
  {
    close(fd);
    return 1;
  }

  // interpreter exist
  for(i=2;i<BUFSIZE-1;i++)
  {
    read(fd, buf+i, 1);
    if(buf[i] == ' ' || buf[i] == '\n' || buf[i] == 0)
      break;
  }
  ebuf = buf + i;
  buf[i] = 0;
  close(fd);
  
  // shift args
  for(i=0;i<MAXARGS;i++)
    if(ecmd->argv[i] == 0)
      break;
  if(i == MAXARGS)
  {
    fprintf(2, "too many args\n");
    return 0;
  }
  while (i)
  {
    ecmd->argv[i] = ecmd->argv[i-1];
    ecmd->eargv[i] = ecmd->eargv[i-1];
    i--;
  }
  ecmd->argv[0] = buf + 2;
  ecmd->eargv[0] = ebuf;
  return 1;
}
