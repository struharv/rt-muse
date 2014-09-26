#include "rt-bench.h"
#include "rt-bench_utils.h"

rtbench_options_t opts;

static int nthreads;
static pthread_t *threads;
static pthread_barrier_t threads_barrier;
static volatile int continue_running;
static ftrace_data_t ft_data = {
  .debugfs = "/sys/kernel/debug",
  .trace_fd = -1,
  .marker_fd = -1,
};

static inline busywait(struct timespec *to) {
  struct timespec t_step;
  while (1) {
    clock_gettime(CLOCK_THREAD_CPUTIME_ID, &t_step);
    if (!timespec_lower(&t_step, to))
      break;
  }
}

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
  busywait(&t_exec);
  pthread_mutex_unlock(&opts.resources[resource_id].mtx);
}

static void shutdown(int sig) {
  int i;
  /* notify threads, join them, then exit */
  continue_running = 0;
  for (i = 0; i < nthreads; i++)
    pthread_join(threads[i], NULL);
  if (opts.ftrace) {
    close(ft_data.trace_fd);
    close(ft_data.marker_fd);
  }
  exit(EXIT_SUCCESS);
}

void *thread_body(void *arg) {
  return;
}

int main(int argc, char* argv[]) {

  int i;
  struct timespec t_start;
  thread_data_t *tdata;
  char tmp[PATH_LENGTH];

  parse_command_line(argc, argv, &opts);
  nthreads = opts.nthreads;
  threads = malloc(nthreads * sizeof(pthread_t));
  pthread_barrier_init(&threads_barrier, NULL, nthreads);

  /* install signal handlers for proper shutdown */
  signal(SIGQUIT, shutdown);
  signal(SIGTERM, shutdown);
  signal(SIGHUP, shutdown);
  signal(SIGINT, shutdown);

  /* if using ftrace open trace and marker fds */
  if (opts.ftrace) {
    log_notice("configuring ftrace");
    strcpy(tmp, ft_data.debugfs);
    strcat(tmp, "/tracing/tracing_on");
    ft_data.trace_fd = open(tmp, O_WRONLY);
    if (ft_data.trace_fd < 0) {
      log_error("Cannot open trace_fd file %s", tmp);
      exit(EXIT_FAILURE);
    }
    strcpy(tmp, ft_data.debugfs);
    strcat(tmp, "/tracing/trace_marker");
    ft_data.marker_fd = open(tmp, O_WRONLY);
    if (ft_data.trace_fd < 0) {
      log_error("Cannot open trace_marker file %s", tmp);
      exit(EXIT_FAILURE);
    }
    log_ftrace(ft_data.trace_fd, "1");
    log_ftrace(ft_data.marker_fd, "main creates threads\n");
  }

  continue_running = 1;

  /* Take the beginning time for everything */
  clock_gettime(CLOCK_MONOTONIC, &t_start);

  /* start threads */
  for (i = 0; i < nthreads; i++) {
    tdata = &opts.threads_data[i];
    tdata->duration = opts.duration;
    tdata->main_app_start = t_start;
    tdata->lock_pages = opts.lock_pages;
    if (opts.logdir) {
      snprintf(tmp, PATH_LENGTH, "%s/%s-%s.log",
         opts.logdir,
         opts.logbasename,
         tdata->name);
      tdata->log_handler = fopen(tmp, "w");
      if (!tdata->log_handler){
        log_error("Cannot open logfile %s", tmp);
        exit(EXIT_FAILURE);
      }
    } else {
      tdata->log_handler = stdout;
    }

    if (pthread_create(&threads[i],
          NULL, 
          thread_body, 
          (void*) tdata))
      exit(EXIT_FAILURE);
  }

  if (opts.duration > 0) {
    sleep(opts.duration);
    if (opts.ftrace)
      log_notice("main shutdown");
    shutdown(SIGTERM);
  }

  for (i = 0; i < nthreads; i++)  {
    pthread_join(threads[i], NULL);
  }

  if (opts.ftrace) {
    log_notice("stopping ftrace");
    log_notice("main ends\n");
    close(ft_data.trace_fd);
    close(ft_data.marker_fd);
  }

  exit(EXIT_SUCCESS);

}