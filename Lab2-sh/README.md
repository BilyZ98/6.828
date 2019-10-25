# Lab Record

## wait system call
It can only wait for a single child.  
So if the shell encounters many pipes, i.e. it needs to `fork` many children and then `exec`  
then it has to call `wait(0)`  multiple times to wait for them.

## pipe and io redirection precedence
pipe is for programs, somehow dynamic.  
io redirection is for reading or writing files, somehow static.  

shell implemention
1. divide up the cmd according to `|` first
2. then we have multiple programs(subcmds) to be executed (pipe used at this stage)
3. in each programs, we analyze the io redirection and then ultimately execute it (io redirection used at this stage)

now we know, at least from the shell's perspective,  
pipes change programs' **fds** before io redirection.