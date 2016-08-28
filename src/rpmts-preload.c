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

#include <curl/curl.h>

CURL* curl_easy_init() {
  CURL* ret;
  CURL* (*original_init)();
  CURLcode (*curl_easy_setopt)(CURL*, CURLoption, ...);

  original_init = dlsym(RTLD_NEXT, "curl_easy_init");
  curl_easy_setopt = dlsym(RTLD_DEFAULT, "curl_easy_setopt");

  ret = (*original_init)();
  (*curl_easy_setopt)(ret, CURLOPT_VERBOSE, 1L);

  return ret;
}
