#if defined(_WIN32)
#define WIN32_LEAN_AND_MEAN
#include <windows.h>  // GetTokenInformation
#else
#include <unistd.h>  // geteuid
#include <sys/types.h>  // geteuid, pid_t
#endif

#include "ffilesystem.h"


bool fs_is_admin(){
  // running as admin / root / superuser
#if defined(_WIN32)
  HANDLE hToken = nullptr;
  TOKEN_ELEVATION elevation;
  DWORD dwSize;

  const bool ok = (OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &hToken) &&
     GetTokenInformation(hToken, TokenElevation, &elevation, sizeof(elevation), &dwSize));

  if(hToken)
    CloseHandle(hToken);
  if(ok)
    return elevation.TokenIsElevated;

  return false;
#else
  return geteuid() == 0;
#endif
}
