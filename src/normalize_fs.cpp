#include <string>
#include <string_view>
#include <algorithm> // std::unique

#include <filesystem>

#include "ffilesystem.h"


std::string fs_drop_slash(std::string_view in)
{
  // drop all trailing "/" and duplicated internal "/"

  std::filesystem::path p(in);

  std::string s = p.generic_string();

  if (!fs_is_windows() || p != p.root_path()){
    while(s.length() > 1 && s.back() == '/')
      s.pop_back();
  }

  s.erase(std::unique(s.begin(), s.end(), [](char a, char b){ return a == '/' && b == '/'; }), s.end());

  return s;
}


std::string fs_normalize(std::string_view path)
{
  std::filesystem::path p(path);

  std::string r = p.lexically_normal().string();

  // no trailing slash
  if (r.length() > 1 && (r.back() == '/' || (fs_is_windows() && r.back() == '\\')) && (!fs_is_windows() || p != p.root_path()))
    r.pop_back();

  if (r.empty())
    r.push_back('.');

  return r;
}
