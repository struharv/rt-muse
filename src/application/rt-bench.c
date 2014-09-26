#include "rt-bench.h"

rtbench_options_t opts;

void sleep_for (int ind, ...) {
  struct timespec *t_sleep, t_now;
  va_list argp;
  va_start(argp, ind);
  t_sleep = va_arg(argp, struct timespec*);
  va_end(argp);
  clock_gettime(CLOCK_MONOTONIC, &t_now);
  t_now = timespec_add(&t_now, t_sleep);
  clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &t_now, NULL);
}

void compute (int ind, ...) {
  unsigned int loops, i, counter = 0;
  struct timespec *t_spec;
  va_list argp;
  va_start(argp, ind);
  t_spec = va_arg(argp, struct timespec*);
  va_end(argp);
  loops = timespec_to_usec(t_spec);
  for (i = 0; i < loops; i++)
    counter = (++counter) * i;
}

void lock(int ind, ...) {
  int resource_id;
  struct timespec t_start, now, t_exec, t_totexec;
  struct timespec *t_spec;
  va_list argp;
  va_start(argp, ind);
  t_spec = va_arg(argp, struct timespec*);
  resource_id = va_arg(argp, int);
  va_end(argp);
  clock_gettime(CLOCK_THREAD_CPUTIME_ID, &t_start);
  pthread_mutex_lock(&opts.resources[resource_id].mtx);
  clock_gettime(CLOCK_THREAD_CPUTIME_ID, &now);
  t_exec = timespec_add(&now, t_spec);
  //busywait(&t_exec);
  pthread_mutex_unlock(&opts.resources[resource_id].mtx);
}

int main(int argc, char* argv[]) {

  parse_command_line(argc, argv, &opts);

  exit(EXIT_SUCCESS);

}