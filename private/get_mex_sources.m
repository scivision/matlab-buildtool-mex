function srcs = get_mex_sources(build_all)
arguments (Input)
  build_all (1,1) logical = false
end
arguments (Output)
  srcs cell
end

srcs = {
% "src/remove.cpp", ...
%["src/normalize.cpp", "src/normalize_fs.cpp", "src/pure.cpp"], ...
% "src/set_permissions.cpp"
};

if ~stdlib.has_python() || build_all
srcs{end+1} = "src/is_char_device.cpp";
srcs{end+1} = ["src/is_admin.cpp", "src/admin_fs.cpp"];
% srcs{end+1} = "src/disk_available.cpp";
% srcs{end+1} = "src/disk_capacity.cpp";
end

end
