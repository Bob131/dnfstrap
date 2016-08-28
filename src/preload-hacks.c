#define _GNU_SOURCE
#include <dlfcn.h>

#include <rpm/rpmprob.h>

/*
 * Calling rpmtsRun without any problem filters will cause librpm to refuse to
 * install packages for a different arch or OS. Since this is the way libdnf
 * invokes rpmtsRun, we override it with our own function that adds in the
 * flags we need.
 */
int rpmtsRun(rpmts ts) {
  rpmprobFilterFlags flags = RPMPROB_FILTER_IGNOREOS
    | RPMPROB_FILTER_IGNOREARCH;

  int (*original_run)(rpmts ts, rpmps okProbs, rpmprobFilterFlags flags);
  original_run = dlsym(RTLD_NEXT, "rpmtsRun");
  return (*original_run)(ts, NULL, flags);
}

#include <curl/curl.h>

/*
 * Curl doesn't have any handy environment variables or the like to enable
 * debug-spew, so here we just override curl_easy_init() to add the verbose
 * option ourselves.
 */
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
