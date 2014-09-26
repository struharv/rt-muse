#include "rt-bench_utils.h"

struct timespec usec_to_timespec(unsigned long usec) {
  struct timespec ts;
  ts.tv_sec = usec / 1000000;
  ts.tv_nsec = (usec % 1000000) * 1000;
  return ts;
}

unsigned long timespec_to_usec(struct timespec *ts) {
  return round((ts->tv_sec * 1E9 + ts->tv_nsec) / 1000.0);
}

int string_to_policy(const char *policy_name, policy_t *policy) {
  if (strcmp(policy_name, "SCHED_OTHER") == 0)
    *policy = other;
  else if (strcmp(policy_name, "SCHED_RR") == 0)
    *policy =  rr;
  else if (strcmp(policy_name, "SCHED_FIFO") == 0)
    *policy =  fifo;
  else if (strcmp(policy_name, "SCHED_DEADLINE") == 0)
    *policy =  deadline;
  else
    return 1;
  return 0;
}

int policy_to_string(policy_t policy, char *policy_name) {
  switch (policy) {
    case other:
      strcpy(policy_name, "SCHED_OTHER");
      break;
    case rr:
      strcpy(policy_name, "SCHED_RR");
      break;
    case fifo:
      strcpy(policy_name, "SCHED_FIFO");
      break;     
    case deadline:
      strcpy(policy_name, "SCHED_DEADLINE");
      break;
    default:
      return 1;
  }
  return 0;
}

int string_to_phase(const char *phase_name, phase_t *phase) {
  if (strncmp(phase_name, "s", 1) == 0)
    *phase =  SLEEP;
  else if (strncmp(phase_name, "c", 1) == 0)
    *phase =  COMPUTE;
  else if (strncmp(phase_name, "l", 1) == 0)
    *phase =  LOCK;
  else
    return 1;
  return 0;
}

struct timespec timespec_add(struct timespec *t1, struct timespec *t2) {
  struct timespec ts;
  ts.tv_sec = t1->tv_sec + t2->tv_sec;
  ts.tv_nsec = t1->tv_nsec + t2->tv_nsec;
  while (ts.tv_nsec >= 1E9) {
    ts.tv_nsec -= 1E9;
    ts.tv_sec++;
  }
  return ts;
}
