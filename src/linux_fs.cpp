#include <string_view>

#if __has_include(<sys/utsname.h>)
#define HAVE_UTSNAME
#include <sys/utsname.h>
#endif

#include "ffilesystem.h"


int fs_is_wsl()
{

#ifdef HAVE_UTSNAME
  struct utsname buf;
  if (uname(&buf) != 0)
    return -1;

  std::string_view s(buf.sysname);
  std::string_view r(buf.release);

  if(s != "Linux")
    return 0;
#ifdef __cpp_lib_starts_ends_with // C++20
  if (r.ends_with("microsoft-standard-WSL2"))
    return 2;
  if (r.ends_with("-Microsoft"))
    return 1;
#endif
#endif
  return 0;
}
