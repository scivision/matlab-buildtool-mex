#include <string>
#include <string_view>
#include <cstddef>

bool fs_is_windows();
std::size_t fs_get_max_path();
std::string fs_as_posix(std::string_view);
std::string fs_drop_slash(std::string_view);
std::string fs_normalize(std::string_view path);
std::string fs_as_posix(std::string_view);

bool fs_is_url(std::string_view);
int fs_is_wsl();
bool fs_is_rosetta();
bool fs_is_admin();

bool fs_is_absolute(std::string_view);

bool fs_is_symlink(std::string_view);
bool fs_create_symlink(std::string_view, std::string_view);
std::string fs_read_symlink(std::string_view);

std::string fs_parent(std::string_view);

std::string fs_root_dir(std::string_view);
std::string fs_root_name(std::string_view);

bool fs_win32_is_symlink(std::string_view);
std::string fs_shortname(std::string_view);
