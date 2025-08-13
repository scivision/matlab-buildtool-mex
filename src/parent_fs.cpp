#include <string>
#include <string_view>

#include <filesystem>

#include "ffilesystem.h"

std::string fs_parent(std::string_view in)
{

  std::string s(in);
  while (s.length() > 1 && (s.back() == '/' || (fs_is_windows() && s.back() == '\\')))
    s.pop_back();

  auto par = std::filesystem::path(s).parent_path();

  if (par.empty())
    return ".";

  // need this for <filesystem> or _splitpath_s to make x: x:/
  if (fs_is_windows() && par == par.root_name())
    par += '/';

  return par.string();
}
