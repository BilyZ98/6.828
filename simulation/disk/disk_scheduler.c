#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BUFSIZE 100
#define MAXREQ 100

enum scheduler
{
    FCFS,
    SSTF,
    SCAN
};
int req[MAXREQ];

void generate(int);
double fcfs(int, int);
double sstf(int, int);
double scan(int, int);
double (*sche_fn[])(int, int) = {
    [FCFS] fcfs,
    [SSTF] sstf,
    [SCAN] scan,
};

int main()
{
    char buf[BUFSIZE];
    int algorithm;

    printf("You are in disk scheduler now.\n");
    while (1)
    {
        printf("> ");
        scanf("%s", buf);

        // check schedule algorithm
        if (!strcmp(buf, "use"))
        {
            scanf("%s", buf);
            if (!strcmp(buf, "FCFS"))
                algorithm = FCFS;
            else if (!strcmp(buf, "SSTF"))
                algorithm = SSTF;
            else
                algorithm = SCAN;
            continue;
        }

        if (!strcmp(buf, "test"))
        {
            int i, start, n;
            double cost;

            printf("start at: ");
            scanf("%d", &start);
            printf("num of request: ");
            scanf("%d", &n);

            for (i = 0; i < n; i++)
                scanf("%d", &req[i]);

            cost = sche_fn[algorithm](start, n);
            printf("平均寻道长度: %lf\n", cost);
            continue;
        }

        if (!strcmp(buf, "benchmark"))
        {
            int start = 100;
            int times = 100;
            int i, n = 40;
            double cost[3] = {0, 0, 0};

            for (i = 0; i < times; i++)
            {
                generate(n);
                cost[0] += fcfs(start, n);
                cost[1] += sstf(start, n);
                cost[2] += scan(start, n);
            }

            cost[0] /= times;
            cost[1] /= times;
            cost[2] /= times;

            printf("benchmark测试性能：\n");
            printf("测试次数：%d, 起始磁道：%d, request次数：%d\n", times, start, n);
            printf("fcfs平均寻道长度: %lf\n", cost[0]);
            printf("sstf平均寻道长度: %lf\n", cost[1]);
            printf("scan平均寻道长度: %lf\n", cost[2]);
        }
    }
}

double fcfs(int start, int n)
{
    int i;
    double cost = 0;

    for (i = 0; i < n; i++)
    {
        cost += abs(start - req[i]);
        start = req[i];
    }

    return cost / n;
}

double sstf(int start, int n)
{
    int i, j, lowi, lowcost;
    int finish[MAXREQ];
    double cost = 0;

    memset(finish, 0, sizeof(finish));

    for (i = 0; i < n; i++)
    {
        lowi = -1;
        for (j = 0; j < n; j++)
        {
            if (finish[j])
                continue;
            if (lowi == -1 || abs(req[j] - start) < lowcost)
            {
                lowi = j;
                lowcost = abs(req[j] - start);
            }
        }
        finish[lowi] = 1;
        cost += lowcost;
        start = req[lowi];
    }

    return cost / n;
}

double scan(int start, int n)
{
    int i, j, lowi, lowcost;
    int direction = 1;
    int finish[MAXREQ];
    double cost = 0;

    memset(finish, 0, sizeof(finish));

    for (i = 0; i < n; i++)
    {
        lowi = -1;
        for (j = 0; j < n; j++)
        {
            if (finish[j] || (req[j] - start) * direction < 0)
                continue;
            if (lowi == -1 || abs(req[j] - start) < lowcost)
            {
                lowi = j;
                lowcost = abs(req[j] - start);
            }
        }
        if (lowi == -1)
        {
            i--;
            direction *= -1;
            continue;
        }

        finish[lowi] = 1;
        cost += lowcost;
        start = req[lowi];
    }

    return cost / n;
}

void generate(int n)
{
    int i;
    for (i = 0; i < n; i++)
        req[i] = (int)(rand() % 200 + 1);
}