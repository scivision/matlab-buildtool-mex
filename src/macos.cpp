#if defined(__APPLE__) && defined(__MACH__)
#include <cerrno>
#include <sys/sysctl.h>
#endif

#include "ffilesystem.h"


bool fs_is_rosetta()
{
#if defined(__APPLE__) && defined(__MACH__)
// https://developer.apple.com/documentation/apple-silicon/about-the-rosetta-translation-environment
  int ret = 0;
  size_t size = sizeof(ret);

  if (sysctlbyname("sysctl.proc_translated", &ret, &size, nullptr, 0) < 0)
    return false;

  return ret == 1;
#else
  return false;
#endif
}
