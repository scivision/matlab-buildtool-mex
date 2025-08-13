#include "mex.hpp"
#include "mexAdapter.hpp"

#include <string>
#include <string_view>

#include <vector>
#include <memory>

#if defined(_MSC_VER)
# define WIN32_LEAN_AND_MEAN
# include <windows.h>
#else
# include <filesystem>
# include <system_error>
#endif


static bool fs_is_char_device(std::string_view path)
{
// character device like /dev/null or CONIN$
#if defined(_MSC_VER)
  // currently broken in MSVC STL for <filesystem>
  HANDLE h =
    CreateFileA(path.data(), GENERIC_READ, FILE_SHARE_READ,
                nullptr, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, nullptr);
  if (h == INVALID_HANDLE_VALUE)
    return false;

  const DWORD type = GetFileType(h);
  CloseHandle(h);
  return type == FILE_TYPE_CHAR;
#else
  std::error_code ec;
  return std::filesystem::is_character_file(path, ec) && !ec;
#endif
}


class MexFunction : public matlab::mex::Function {
private:
#include "mex1string.inl"

public:
  void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs)
  {
    matlab::data::ArrayFactory factory;

    outputs[0] = factory.createScalar<bool>(fs_is_char_device(matlab_1string_input(inputs)));
  }
};
