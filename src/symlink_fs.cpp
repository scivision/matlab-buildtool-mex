#if defined(__MINGW__)
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#endif

#include <string>
#include <string_view>

#include <filesystem>
#include <system_error>

#include "ffilesystem.h"


bool fs_create_symlink(std::string_view target, std::string_view link)
{
  // confusing program errors if target is "" -- we'd never make such a symlink in real use.
  if(target.empty())
    return false;

  // macOS needs empty check to avoid SIGABRT
  if(link.empty())
    return false;

#if defined(__MINGW32__)

  const DWORD attr = GetFileAttributesA(target.data());
// https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-getfileattributesa
// https://learn.microsoft.com/en-us/windows/win32/fileio/file-attribute-constants

  if (attr == INVALID_FILE_ATTRIBUTES)
    return false;

  DWORD p = SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE;
  if(attr & FILE_ATTRIBUTE_DIRECTORY)
    p |= SYMBOLIC_LINK_FLAG_DIRECTORY;

  return CreateSymbolicLinkA(link.data(), target.data(), p);
#else
  std::error_code ec;
  std::filesystem::path t(target);

  bool isdir = std::filesystem::is_directory(t, ec);
  if (ec)
    return false;

  isdir
    ? std::filesystem::create_directory_symlink(t, link, ec)
    : std::filesystem::create_symlink(t, link, ec);

  return !ec;
#endif
}


bool fs_is_symlink(std::string_view path)
{

#if defined(__MINGW32__)
  return fs_win32_is_symlink(path);
#else
// std::filesystem::symlink_status doesn't detect symlinks on MinGW
  std::error_code ec;
  const auto s = std::filesystem::symlink_status(path, ec);
  return !ec && std::filesystem::is_symlink(s);
#endif
}


std::string fs_read_symlink(std::string_view path)
{

#if defined(__MINGW32__)
  if(fs_is_symlink(path))
    return fs_win32_final_path(path);
#else
  std::error_code ec;
  if(auto p = std::filesystem::read_symlink(path, ec); !ec)
    return p.string();
  // need .string() explict for MSVC
#endif

  return {};
}
