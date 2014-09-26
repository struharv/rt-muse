#ifndef _RT_BENCH_H_
#define _RT_BENCH_H_

#include <stdlib.h>
#include <stdio.h>
#include <error.h>
#include <time.h>
#include <sched.h>
#include <pthread.h>
#include <signal.h>
#include "rt-bench_types.h"
#include "rt-bench_args.h"

void *thread_body(void *arg);

#endif /* _RT_BENCH_H_ */

