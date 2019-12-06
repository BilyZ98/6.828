## Warning

## Command
### create
for creating process
```
create proc_name priority
```

### show
show process or resource state
```
show
show proc
show resc
```

### run
fetch a process in ready list to run
```
run
```

### finish
try to finish the process currently running
```
finish
```

### request
request resource for currently running process
```
request [pid] [rid]
```

### timeout
make the running process timeout, i.e., into block list
```
timeout
```

### activate
check block list, activate procs to be ready
```
activate
```

## example
```
> create A 1
> create B 2
> create C 3
> run               // A runs
> request 0 10
> request 0 7
> timeout           // make proc A timeout
> activate          // proc A switch from blocked to ready
> run               // B runs
> request 1 4
> request 1 7       // B blocks!
> run               // C runs
> request 2 18
> request 2 10      // C blocks!
> activate
> run               // A runs again
> finish            // A finishs
> activate          // B and C get ready now
...
```