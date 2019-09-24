#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/fs.h"
#include "user.h"

#define PATHLEN 512

void find(char *dirpath, char *filename);

int main(int argc, char *argv[])
{
    char dirpath[PATHLEN], *filename;

    if (argc != 3)
    {
        printf("usage: find [DIR_PATH] [FILE]\n");
        exit();
    }

    strcpy(dirpath, argv[1]);
    filename = argv[2];
    find(dirpath, filename);
    exit();
}

void find(char *dirpath, char *filename)
{
    int fd;
    char *p;
    struct stat st;
    struct dirent de;

    if ((fd = open(dirpath, 0)) < 0)
    {
        fprintf(2, "find cannot open %s\n", dirpath);
        return;
    }

    if (fstat(fd, &st) < 0)
    {
        fprintf(2, "find: cannot stat %s\n", dirpath);
        close(fd);
        return;
    }

    if (strlen(dirpath) + 1 + DIRSIZ + 1 > PATHLEN)
    {
        fprintf(2, "find: path too long %s\n", dirpath);
        close(fd);
        return;
    }
    p = dirpath + strlen(dirpath);
    *p++ = '/';

    if (st.type == T_DIR)
    {
        while (read(fd, &de, sizeof(de)) == sizeof(de))
        {
            if (de.inum == 0)
                continue;
            if (!strcmp(de.name, ".") || !strcmp(de.name, ".."))
                continue;
                
            memmove(p, de.name, DIRSIZ);
            p[DIRSIZ] = 0;
            if (stat(dirpath, &st) < 0)
            {
                fprintf(2, "find: cannot stat %s\n", dirpath);
                continue;
            }
            if (st.type == T_DIR)
                find(dirpath, filename);
            else if (!strcmp(de.name, filename))
                printf("%s\n", dirpath);
        }
    }
    else
        fprintf(2, "find: enter correct dir path %s\n", dirpath);

    close(fd);
    return;
}
