#define _GNU_SOURCE

#include <rpm/rpmprob.h>
#include <dlfcn.h>

int rpmtsRun(rpmts ts) {
  rpmprobFilterFlags flags = RPMPROB_FILTER_IGNOREOS
    | RPMPROB_FILTER_IGNOREARCH;

  int (*original_run)(rpmts ts, rpmps okProbs, rpmprobFilterFlags flags);
  original_run = dlsym(RTLD_NEXT, "rpmtsRun");
  return (*original_run)(ts, NULL, flags);
}
