function opts = get_compiler_options()
arguments (Output)
  opts (1,1) string
end
% mex() can't handle string.empty

cxx = mex.getCompilerConfigurations('c++');
flags = cxx.Details.CompilerFlags;

msvc = startsWith(cxx.ShortName, "MSVCPP");

std = "-std=c++17";

opts = "";
if msvc
  std = "/std:c++17";
  % on Windows, Matlab doesn't register unsupported MSVC or oneAPI
elseif cxx.ShortName == "g++"
  if ~stdlib.version_atleast(cxx.Version, "8")
    warning("g++ 8 or newer is required for MEX, detected g++" + cxx.Version)
  end

  if ~stdlib.version_atleast(cxx.Version, "9")
    opts = "-lstdc++fs";
  end
end

opt = flags + " " + std;
if msvc
  opts = opts + "COMPFLAGS=" + opt;
else
  opts = opts + "CXXFLAGS=" + opt;
end

end
