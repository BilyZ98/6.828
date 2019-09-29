#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/fs.h"
#include "user.h"

#define PATHLEN 512

void find(char *dirpath, char *filename);
int match(char*, char*);

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
            else if (match(filename, de.name))
                printf("%s\n", dirpath);
        }
    }
    else
        fprintf(2, "find: enter correct dir path %s\n", dirpath);

    close(fd);
    return;
}

// Regexp matcher from Kernighan & Pike,
// The Practice of Programming, Chapter 9.

int matchhere(char*, char*);
int matchstar(int, char*, char*);

int
match(char *re, char *text)
{
  if(re[0] == '^')
    return matchhere(re+1, text);
  do{  // must look at empty string
    if(matchhere(re, text))
      return 1;
  }while(*text++ != '\0');
  return 0;
}

// matchhere: search for re at beginning of text
int matchhere(char *re, char *text)
{
  if(re[0] == '\0')
    return 1;
  if(re[1] == '*')
    return matchstar(re[0], re+2, text);
  if(re[0] == '$' && re[1] == '\0')
    return *text == '\0';
  if(*text!='\0' && (re[0]=='.' || re[0]==*text))
    return matchhere(re+1, text+1);
  return 0;
}

// matchstar: search for c*re at beginning of text
int matchstar(int c, char *re, char *text)
{
  do{  // a * matches zero or more instances
    if(matchhere(re, text))
      return 1;
  }while(*text!='\0' && (*text++==c || c=='.'));
  return 0;
}
