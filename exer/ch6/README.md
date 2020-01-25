# ch6 - Exercise

## exercise 1
*lost wakeup* might occur:  
caller/proc of `sleep` and `wakeup` both acquire the condition lock first,  
then they call `sleep` or `wakeup`.  
so if we put `release(lk)` before `acquire(&p->lock)` in `sleep`,  
`wakeup` is able to run between these two sentences.

## exercise 2
```
For example, creating a file requires simultaneously holding a lock on the directory, a lock on the
new file’s inode, a lock on a disk block buffer, the disk driver’s vdisk_lock, and the calling process’s p->lock. To avoid deadlock, file-system code always acquires locks in the order mentioned
in the previous sentence.
```
(if closing file in `wait`)calling `fileclose` with proc's lock held will cause deadlock,  
because some lock in `fileclose` might sleep and then this proc will never be waken up.

## exercise 3
implements semaphore and use it in *pipe.c*  
pass *usertests*

## exercise 4
solution: atomically check p->killed and sleep  
this solution should be combined with the plan in exercise 5

## exercise 5
TODO - may be done after learning file system

## exercise 6
TODO and FAILED

goal:  
use only once process switch when switching between kernel thread  

solution:  
add another kind of process switch,  
one is *forced process switch*(already exist in xv6-riscv),  
the other is *planned process switch*(newly added, only for `sleep` temporarily).  
(note: `sched` used in `yield`, `exit` and `sleep`)

plan:  
adding `planned_sched` and `forced_sched`

## exercise 7
TODO

## exercise 8
TODO
