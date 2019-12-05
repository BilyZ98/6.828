CC = gcc
CFLAGS = -Wall -Werror

kernel: main.o cmd.o proc.o
	$(CC) $(CFLAGS) -o kernel $^

clean:
	rm kernel *.o