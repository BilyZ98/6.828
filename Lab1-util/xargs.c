#include "kernel/types.h"
#include "kernel/param.h"
#include "user.h"

#define BUFLEN 512

int
main(int argc, char *argv[])
{
	int i_arg, next_arg, len;
	char *child_argv[MAXARG], *p, buf[BUFLEN];

	if (argc < 2)
	{
		fprintf(2, "usage: xargs [PROGRAM] [ARGS...]\n");
		exit();
	}

	child_argv[0] = argv[1];
	for (next_arg = 1; next_arg + 1 < argc; next_arg++)
		child_argv[next_arg] = argv[next_arg + 1];
	while (gets(buf, BUFLEN) && (len = strlen(buf)))
	{
		i_arg = next_arg;
		p = buf;
		do
		{
			while (*p == ' ')
				p++;
			if (*p == '\n' || *p == '\r')
				break;
			child_argv[i_arg++] = p;
			if (i_arg == MAXARG)
			{
				fprintf(2, "xargs: too many arguments, must fewer than %d", (int)MAXARG);
				exit();
			}
			while (*p != ' ' && *p != '\n' && *p != '\r')
				p++;
			if (*p==' ')
				*p++ = '\0';
			else
				break;
		} while (1);
		*p = '\0';
		child_argv[i_arg] = 0;
		if (fork() == 0)
			exec(child_argv[0], child_argv);
		wait();
	}

	exit();
}