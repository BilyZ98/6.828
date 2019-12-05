enum type
{
    ERROR,
    CREATE,
    RUN,
    FINISH,
    REQUEST,
    DELETE,
    SHOW
};

struct cmd
{
    enum type type;
    char proc_name[16];
    int priority;
    int rid;
};