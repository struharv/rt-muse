rt-bench
========

Global:
  duration, default value 1
  default_policy (SCHED_OTHER, SCHED_RR, SCHED_FIFO, SCHED_DEADLINE), default value SCHED_OTHER
  logdir, default value "./"
  logbasename, default value "rt-bench.log"
  lock_pages, default value TRUE
  ftrace, default value FALSE

Thread:
  period
  exec
  policy
  priority
  deadline
  hard_rsv
  cpus
  phases

  for each phase:
    duration
  if phase lock:
    resource_id
