#include <stdio.h>

int getfloat(float *pf);

int main()
{
    int rc;
    float fx;
    while ((rc = getfloat(&fx)) > 0)
        printf("getfloat: %f\n", fx);
    if (rc == 0)
        fprintf(stderr, "getfloat: error\n");

    return 0;
}

// getint function from K&R,
// The C Programming Language, Chapter 5, Section 2.

int getfloat(float *pf)
{
    int i, c, sign;

    while (isspace(c = getc(stdin)))
        ;
    if (!isdigit(c) && c != EOF && c != '+' && c != '-')
    {
        ungetc(c, stdin);
        return 0;
    }

    sign = (c == '-') ? -1 : 1;
    if (c == '+' || c == '-')
        c = getc(stdin);
    for (*pf = 0; isdigit(c); c = getc(stdin))
        *pf = 10 * *pf + (c - '0');
    if (c == '.')
    {
        c = getc(stdin);
        for(i = 10; isdigit(c); i*=10, c = getc(stdin))
            *pf += (float)(c - '0') / i;
    }
    *pf *= sign;
    if (c != EOF)
        ungetc(c, stdin);
    return c;
}