#include "kernel/types.h"
#include "user.h"

void testsbrk();

int main(int argc, char *argv[])
{
    testsbrk();
    exit(0);
}

void testsbrk()
{
    sbrk(1);
}