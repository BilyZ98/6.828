enum type
{
    ERROR,
    CREATE,
    RUN,
    FINISH,
    REQUEST,
    SHOW,
    TIMEOUT,
    ACTIVATE
};

struct cmd
{
    enum type type;
    char proc_name[16];
    int priority;
    int pid;
    int rid;
};