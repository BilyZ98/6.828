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
void push_block(int);
struct block_list *delete_block(struct block_list *, struct block_list *);
void timeout();
void activate();

// cmd.c
int getcmd(char *, int);
void parsecmd(char *, int, struct cmd *);
void runcmd(struct cmd *);
void printcmd(struct cmd *);

// main.c
void panic(char *);

// resource.c
void init_resources();
void request(int, int);
void requests(int);
void push_req(int, int);
void push_resc(int, int);
void show_rescs();