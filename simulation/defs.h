struct proc;
struct cmd;

// proc.c
void init_procs();
struct proc *create_proc();
void delete_proc(struct proc *p);
void suspend_proc(struct proc *p);
void wakeup_proc(struct proc *p);
void push_ready(struct proc *p);
void show_procs();
void run_proc();
void fin_proc();

// cmd.c
int getcmd(char *, int);
void parsecmd(char *, int, struct cmd *);
void runcmd(struct cmd *);
void printcmd(struct cmd *);

// main.c
void panic(char *);