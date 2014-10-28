rt-bench
========

rt-bench is a fork of [rt-app](https://github.com/gbagnoli/rt-app)
developed by [Juri Lelli](https://github.com/jlelli) and [Giacomo
Bagnoli](https://github.com/gbagnoli). It is intended to be used as a
scheduler benchmarking tool.

### _Configuration_
rt-bench expects to receive a json file with the configuration to be
tested. An example of configuration file is contained in the folder
input/taskset.json. The json file contains three entries: _resources_,
_global_ and _tasks_.

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
necessary to have a kernel that supports it. SCHED_DEADLINE is
available by default from Linux
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
types of implemented phases. The **compute** phase executes
mathematical operations for a certain number of loop (indicated by the
iterations option).  The **sleep_for** phase sleeps for a certian
number of microseconds (indicated by the duration option). The
**lock** phase locks a resource (indicated by the resource_id option)
and computes for a certian number of iterations (indicated by the
iterations option).

### _Compilation and Execution_ ###

To compile the application it is sufficient to type make in the root
directory. This compiles the
[libdl](https://github.com/gbagnoli/rt-app/tree/master/libdl) and the
application. The binary file should be available in
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

Tests can also be run on a remote machine. The launch script
(launch.sh) automates the procedure of running a test on a remote
machine and saving its results in the results directory. It also
clones the repository and compiles the application on the remote host
if it does not find it (it looks for the repository and the binary
files in the home of the remote host). It can be executed with

```
./launch.sh 127.0.0.1 22 martina input/taskset.json experiment-name
```

where the first parameter is the IP of the remote machine, localhost
works as well, the second parameter is the ssh port for the
connection, the third parameter is the json file to be used, that will
be sent to the remote machine and the last parameter is the name given
to the experiment.  It generates the following output

```
[martina] ~/rt-bench : ls -l results/experiment-name
-rw-r--r-- 1 root root     31528 ott 23 09:37 experiment-name.csv
-rw-r--r-- 1 root root   4509696 ott 23 09:37 experiment-name.dat
-rw-r--r-- 1 root root    344920 ott 23 09:37 experiment-name.txt
```

On the remote machine it generates the following file

```
[martina] ~/rt-bench : ls -l results/experiment-name
-rw-r--r-- 1 root root 144432576 ott 23 09:37 output_experiment-name.txt
```

The file output_experiment-name.txt in the remote machine contain the
output of the application itself and of the tracer. In the local
machine, the csv file contains the time instant of points where the
function was starting the loops, the dat file contains the tracer
outputs and the txt file the readable form of the tracer output.
