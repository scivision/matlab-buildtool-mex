#include "ffilesystem.h"

#include <cstdlib>
#include <string>
#include <string_view>

#if defined(__APPLE__) && defined(__MACH__)
#include <sys/syslimits.h>
#endif
#if __has_include(<limits.h>)
#include <limits.h>
#endif

#include <filesystem>


std::size_t fs_get_max_path()
{
#if defined(PATH_MAX)
  return PATH_MAX;
#elif defined(_WIN32)
  return _MAX_PATH;
#else
  return 1024;
#endif
}


bool fs_is_windows()
{
#if defined(_WIN32)
  return true;
#else
  return false;
#endif
}


std::string fs_as_posix(std::string_view path)
{
  std::filesystem::path p(path);

  return p.generic_string();
}

std::string fs_root_dir(std::string_view path)
{
  return std::filesystem::path(path).root_directory().string();
}

std::string fs_root_name(std::string_view path)
{
  return std::filesystem::path(path).root_name().string();
}


bool fs_is_url(std::string_view path)
{
  return path.find("://") != std::string::npos;
}
