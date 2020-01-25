// Semaphore without condition variable
// i.e. without sleep and wakeup primitives
struct semaphore {
    struct spinlock lock;
    int count;

    // For debugging:
    char *name;
    int pid;    // only useful in binary semaphore
};
