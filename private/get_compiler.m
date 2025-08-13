function [comp, shell] = get_compiler(lang)
arguments
  lang (1,1) string {mustBeMember(lang, ["c", "c++", "fortran"])}
end

shell = string.empty;

lang = lower(lang);

co = mex.getCompilerConfigurations(lang);

if isempty(co)
  switch lang
    case "fortran"
      comp = getenv("FC");
      if isempty(comp)
        disp("set FC environment variable to the Fortran compiler path via get_compiler('fortran'), or do 'mex -setup Fortran")
      end
    case "c++"
      comp = getenv("CXX");
      if isempty(comp)
        disp("set CXX environment variable to the C++ compiler path via get_compiler('c++'), or do 'mex -setup c++")
      end
    case "c"
      comp = getenv("CC");
      if isempty(comp)
        disp("set CC environment variable to the C compiler path via get_compiler('c'), or do 'mex -setup c'")
      end
  end
else
  comp = co.Details.CompilerExecutable;
  % disp(lang + " compiler: " + co.ShortName + " " + co.Name + " " + co.Version + " " + comp)
end
if ~strlength(comp), return, end

if ispc()
  if isempty(co)
    if any(contains(comp, ["gcc", "g++", "gfortran"]))
      shell = "set PATH=" + fileparts(comp) + pathsep + "%PATH%";
    end
  else
    if startsWith(co.ShortName, ["INTEL", "MSVC"])
      shell = join([strcat('"',string(co.Details.CommandLineShell),'"'), ...
                  co.Details.CommandLineShellArg], " ");
    elseif startsWith(co.ShortName, "mingw64")
      shell = "set PATH=" + fileparts(comp) + pathsep + "%PATH%";
    end
  end
end

end
