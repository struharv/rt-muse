rt-bench
========

rt-bench is a fork of [rt-app](https://github.com/gbagnoli/rt-app)
developed by [Juri Lelli](https://github.com/jlelli) and 
[Giacomo Bagnoli](https://github.com/gbagnoli). It is intended to be
used as a scheduler benchmarking tool.

### _Configuration_ ###
rt-bench expects to receive a json file with the configuration to be
tested. An example of configuration file is contained in the folder
input/taskset.json. The json file contains three entries: _resources_, _global_ and _tasks_.

``` 
{
  "resources": 3,
  "global": { ... },
  "tasks": { ... }
}
``` 
The global options contain details about the entire experiment:
``` 
"global" : {
  "duration" : 10,
  "default_policy": "SCHED_OTHER" | "SCHED_RR" | "SCHED_FIFO" | "SCHED_DEADLINE",
  "logdir": "./",
  "logbasename": "rt-bench.log",
  "lock_pages": true,
  "ftrace": false
}
``` 
The duration is expressed in seconds and represents the total duration
of the experiment, the threads are going to be shutdown when the
duration is expired, despite what they might be doing. The scheduling
policy is one of the available one. To use
[SCHED_DEADLINE](http://en.wikipedia.org/wiki/SCHED_DEADLINE), it is
necessary to have a kernel that supports it. SCHED_DEADLINE is available
by default from Linux 
[3.14](http://kernelnewbies.org/Linux_3.14#head-651929cdcf19cc2e2cfc7feb16b78ef963d195fe).
To enable ftrace follow the instructions available
[here](http://lwn.net/Articles/425583/).

The tasks section contains an array of tasks, an example follows:

``` 
"tasks" : {
    "thread1" : {
      "exec" : 50000,
      "period" : 100000,
      "hard_rsv" : false, 
      "policy": "SCHED_OTHER",
      "priority" : 10,
      "cpus" : [1,3],
      "phases" : {
        "c0" : { "iterations" : 1000 },
        "l0" : { "iterations" : 2000, "resource_id" : 0 },
        "s1" : { "duration" : 1000, },
        "l1" : { "iterations" : 3000, "resource_id" : 1 },
        "c1" : { "iterations" : 5000 },
        "l2" : { "iterations" : 1000, "resource_id" : 0 },
      }
    }
}
``` 
The task repeats in loop a certain number of phases. There are three
types of implemented phases. The **compute** phase executes mathematical
operations for a certain number of loop (indicated by the iterations option).
The **sleep_for** phase sleeps for a certian number of microseconds
(indicated by the duration option). The **lock** phase locks a
resource (indicated by the resource_id option) and computes
for a certian number of iterations (indicated by the iterations option).

### _Compilation and Execution_ ###

To compile the application it is sufficient to type make in the
root directory. This compiles the
[libdl](https://github.com/gbagnoli/rt-app/tree/master/libdl) and
the application. The binary file should be available in
**bin/application** once the process terminates. The package
[libjson0-dev](https://packages.debian.org/search?keywords=libjson0-dev)
is necessary for the compilation, together with the pthread library.

Once compiled, it is recommended to execute the application with:
```
sudo trace-cmd record -e 'sched_wakeup*' -e sched_switch -e 'sched_migrate*'
  ./bin/application ./input/taskset.json
```
The resulting trace.dat file can be analyzed using
```
kernelshark
```
or with the report tool, eventually filtering the results
```
trace-cmd report trace.dat
trace-cmd report trace.dat | grep tracing_mark_write
```
