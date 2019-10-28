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

## user/sh.c study and analysis
main:
1. `getcmd`
2. fork a child -> `parsecmd` -> `runcmd`
3. parent -> wait

### parse
parsecmd:
1. `parseline` -> `nulterminate`

parseline:
1. `parsepipe` -> check `backcmd`/`&` -> check `listcmd`/`;`(might recurse into `parseline`)

parsepipe:
1. `parseexec` -> if pipe/`|` appear -> `pipecmd` recurse into `parsepipe`

parseexec:
1. ignore `parseblock`
2. use `execcmd()` to allocate space for `struct execcmd` structure
3. use `parseredirs` and `gettoken` in turn to redir `execcmd`, i.e., might upgrade to `redircmd`

P.S.  
`execcmd`, `redircmd`, `pipecmd`, `backcmd`, `listcmd` are self-explanatory  
note their inclusion relationship

### run
easy part

### helper function
peek:
+ argv list:  
    + char **ps - address of  a pointer to somewhere in an array
    + char *es - an end pointer to somewhere in an array
    + toks - checklist for where it stops
+ operation:  
start from *ps to es, go through `whitespce`, stop if not `whitespace`, and then check if the char is in toks

gettoken:
+ reference K&R section 5.12
+ `q` store the start of token, `eq` store the end (used to set '\0' later in `nulterminate`)
+ operation:  
get token like symbol `<|>&;()` or default tokern such as a word, store the start and end of this token in `q` and `eq`

## sizeof operator
[wikipedia sizeof](https://en.wikipedia.org/wiki/Sizeof):  
```
The sizeof operator computes the required memory storage space of its operand. The operand is written following the keyword sizeof and may be the symbol of a storage space, e.g., a variable, type name, or an expression. If it is a type name, it must be enclosed in parentheses. The result of the operation is the size of the operand in bytes, or the size of the memory representation. For expressions it evaluates to the representation size for the type that would result from evaluation of the expression, which is not performed
```
Usage:
1. data type `sizeof (char)`
2. variable `char c; sizeof(c);`
3. array(only array name) `char buffer[10]; strncpy(buffer, argv[1], sizeof buffer - 1);`
4. more in the reference above