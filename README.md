rt-bench
========

`rt-bench` is a fork of [rt-app](https://github.com/gbagnoli/rt-app) developed by [Juri Lelli](https://github.com/jlelli) and [Giacomo Bagnoli](https://github.com/gbagnoli). It aims to be a scheduler benchmarking tool. The main idea behind `rt-bench` is to close the gap between theory and implementation in Linux scheduling by exposing the real-time characteristics of existing scheduling policies.

### Dependencies, configuration and execution

We suggest to execute `rt-bench` with UDP sockets communication. To do so, one needs two machines, **launcher** and **target**. A test is then launched from the launcher machine and executed on the target machine.

The **launcher** machine needs to be equipped with:
* [trace-cmd](http://lwn.net/Articles/410200/)
* [octave](https://www.gnu.org/software/octave/)
* the `rt-bench` code that can be cloned from the github repository
* an IP-address that is reachable from the target machine

The **target** machine needs to be equipped with:
* [trace-cmd](http://lwn.net/Articles/410200/)
* [libdl](https://github.com/gbagnoli/rt-app/tree/master/libdl)
* [libjson0-dev](https://packages.debian.org/search?keywords=libjson0-dev)
* the `pthread` library
* super user priviledges
* `ssh` connection to and from the launcher machine

We strongly recommend using `ssh-copy-id` in order to not be prompted for password during every step of the execution process. Generate an ssh-key on the launcher machine and copy it to the target one. Instructions can be found [here](http://www.thegeekstuff.com/2008/11/3-steps-to-perform-ssh-login-without-password-using-ssh-keygen-ssh-copy-id/). The test needs to be run with super user priviledges on the target machine, so we also recommend to set up the machine so that no password is asked to execute commands with root priviledges on the target. For that, use `visudo` on the target machine and add `username ALL = NOPASSWD : ALL` to the sudoers list, where `username` is the name of your user.

Once configured the machines as described above, a test can be lauched typing the following command in the launcher machine
```
./launch.sh 127.0.0.1 22 username input/taskset.json experiment-name
```
where the parameters are:
* the IP of the target machine
* the ssh port (usually 22, might be differently configured)
* the username on the remote machine
* the configuration file that determines the test behavior
* a unique name for the experiment

To use [SCHED_DEADLINE](http://en.wikipedia.org/wiki/SCHED_DEADLINE), it is necessary to have a kernel that supports it. SCHED_DEADLINE is available by default from Linux [3.14](http://kernelnewbies.org/Linux_3.14#head-651929cdcf19cc2e2cfc7feb16b78ef963d195fe). To enable ftrace follow the instructions available [here](http://lwn.net/Articles/425583/).

After the experiment is executed on the remote machine, `rt-bench` performs data analysis using octave. The result of the analysis is saved in the result directory on the local machine, in the form of csv files. The analysis uses [jsonlab](http://iso2mesh.sourceforge.net/cgi-bin/index.cgi?jsonlab) to read and extract information from the JSON experiment file. The necessary files have been added to the repository and there is no need of installation, but we would like to thank the authors of `jsonlab` for their contribution.

##### Execution example

This example shows the output of a test. When a test is executed, the shell ouput indicates the different stages of execution. Results are saved in the directory `results/experiment-name` that is created as a subdirectory of the `rt-bench` one.
```
~/rt-bench [>] ./launch.sh 127.0.0.1 22 martina input/taskset.json experiment-name
[LAUNCH] Checking rt-bench presence on remote host ... done
[LAUNCH] Checking rt-bench compilation on remote host ... done
[LAUNCH] Sending json file ... done
[LAUNCH] Creating results directories ... done
[LAUNCH] Starting listener ... done
[LAUNCH] Connecting to remote machine and executing ...
Connection to 127.0.0.1 closed.
[LAUNCH] Extracting data for input/taskset.json ... done
[LAUNCH] Removing unnecessary files ... done
[PROCESS] Processing data of thread 'thread1'
[PROCESS] Processing data of thread 'thread2'
[PROCESS] Processing data of all threads
[PROCESS] Octave/Matlab file 'experiment_data.m' written
[PROCESS]   it contains the experiment data, to be used by
[PROCESS]   'results/experiment-name/analysis.m'
[BESTALPHADELTA_LOW] Found one local max of line through TWO points
[BESTALPHABURST_UPP] Found one local max of line through TWO points
[ANALYSIS] Analysis of thread 'thread1' ... Done
[BESTALPHADELTA_LOW] Found one local max of line through TWO points
[BESTALPHABURST_UPP] Found one local max of line through TWO points
[ANALYSIS] Analysis of thread 'thread2' ... Done
[BESTALPHADELTA_LOW] Found one local max of line through TWO points
[BESTALPHABURST_UPP] Found one local max of line through TWO points
[ANALYSIS] Analysis of all threads ... Done
[ANALYSIS] All output data written to experiment-name.output.txt
[LAUNCH] Default analysis completed!
[LAUNCH] To perform the analysis just run the Octave/Matlab script
[LAUNCH]   analysis.m in the directory ./results/experiment-name/
[LAUNCH] Costumized analysis can be performed by modifying
[LAUNCH]     experiment_data.m, with experiment dependent data, and
[LAUNCH]     analysis.m, which performs the actual analysis.
[LAUNCH]   These files are located in ./results/experiment-name/
~/rt-bench [>] ls results/experiment-name/
analysis.m                  experiment-name.2.slbf.csv    experiment-name.dat
experiment_data.m           experiment-name.2.subf.csv    experiment-name.json
experiment-name.1.csv       experiment-name.all.csv       experiment-name.output.txt
experiment-name.1.slbf.csv  experiment-name.all.slbf.csv  experiment-name.txt
experiment-name.1.subf.csv  experiment-name.all.subf.csv  plotSupply.m
experiment-name.2.csv       experiment-name.csv
```

##### Running on a local machine

It is also possible to run an experiment only on a local machine and record execution traces. To do so, one must download the code for `rt-bench` on the machine and type `make` to compile the application (depends on [trace-cmd](http://lwn.net/Articles/410200/), [libdl](https://github.com/gbagnoli/rt-app/tree/master/libdl) and [libjson0-dev](https://packages.debian.org/search?keywords=libjson0-dev)). Once compiled, it is recommended to execute the application with:
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

### Input file

rt-bench expects to receive a json file with the configuration to be tested. An example of configuration file is contained in the folder input/taskset.json. The json file contains four entries: _resources_, _shared_, _global_ and _tasks_.

``` 
{
  "resources": 3,
  "shared": 10,
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
The resources option decides how many resources can be locked. The shared option decides the size of the memory shared among the threads (the number indicates the number of doubles shared among the threads).

The duration is expressed in seconds and represents the total duration of the experiment, the threads are going to be shutdown when the duration is expired, despite what they might be doing. The scheduling policy is one of the available one. 
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
        "c0" : { "loops" : 1000 },
        "l0" : { "loops" : 2000, "resource_id" : 0 },
        "s0" : { "loops" : 1000, },
        "m0" : { "loops" : 1000, "memory": 100 },
        "l1" : { "loops" : 3000, "resource_id" : 1 },
        "c1" : { "loops" : 5000 },
        "l2" : { "loops" : 1000, "resource_id" : 0 },
        "z0" : { "duration" : 10, },
      }
    }
}
``` 

The example defines one task named "thread1". The name of a task should contain only literals and numbers and should start with a literal. Spaces and special characters are not supported. The task repeats in loop a certain number of phases. There are five types of implemented phases. The **compute** phase (name starting with literal c) executes mathematical operations for a certain number of loops (indicated by the loops option).  The **sleep_for** phase (name starting with literal z) sleeps for a certain number of microseconds (indicated by the duration option). The **lock** phase (name starting with literal l) locks a resource (indicated by the resource_id option) and computes for a certain number of iterations (indicated by the loops option). The **memory** phase (name starting with literal m) allocates some memory (an amount of double values indicated by the memory option) and computes mathematical operations writing the results in the vector of doubles allocated, freeing the memory after a some operations (indicated by the loops option). The **shared** phase behaves as the memory phase, but saves the result in the shared buffer of size given by the shared option at the top level.
