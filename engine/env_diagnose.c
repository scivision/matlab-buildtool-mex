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
   "dummy_LIBRARY_PATH"; // dummy name to bypass macOS security - cannot even start with DYLD !
  p = getenv(reqEnv);
  if (!p){
    fprintf(stderr, "C exe: workaround environment variable %s not set, run will fail, aborting...\n", reqEnv);
    return false;
  }
  reqEnv = "DYLD_LIBRARY_PATH";
  if(setenv(reqEnv, p, 1) != 0){
    fprintf(stderr, "C exe: error setting environment variable %s\n", reqEnv);
    return false;
  }
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
    fprintf(stderr, "C exe: environment variable %s not set, run will fail, aborting...\n", reqEnv);
    return false;
  }
  printf("%s: %s\n", reqEnv, p);

  return true;
}
