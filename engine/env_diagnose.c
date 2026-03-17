#include "env_diagnose.h"

#include "stdio.h"
#include "stdlib.h"

#if __STDC_VERSION__ < 202311L
#include <stdbool.h>
#endif


bool env_diagnose(void)
{
  char* p;

  const char* reqEnv =
#ifdef __APPLE__
   "DYLD_LIBRARY_PATH";
#elif defined(__linux__)
   "LD_LIBRARY_PATH";
#elif defined(_WIN32)
   "PATH";
#endif

#ifndef _WIN32
  p = getenv("PATH");
  if(p)
    printf("PATH: %s\n", p);
#endif

  p = getenv(reqEnv);
  if(!p) {
    fprintf(stderr, "Environment variable %s not set, run may fail.\n", reqEnv);
    return false;
  }
  printf("%s: %s\n", reqEnv, p);

  return true;
}
