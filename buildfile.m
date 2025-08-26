function plan = buildfile
assert(~isMATLABReleaseOlderThan("R2024b"))

plan = buildplan(localfunctions);

plan.DefaultTasks = "test";


mexFolder = plan.RootFolder + "/mex";
engFolder = plan.RootFolder + "/engine";

fcflags = "";
fc = mex.getCompilerConfigurations('fortran');
if ~isempty(fc)
  if fc.ShortName == "gfortran"
    fcMajor = regexp(fc.Version, "^(\d+)(?=\.)", "match", "once");
    if str2double(fcMajor) < 10
      warning("GFortran 10 is recommended")
    end
  elseif startsWith(fc.ShortName, "INTEL")
    if contains(fc.Details.CompilerFlags, "/fixed")
      % The mex_FORTRAN_win64.xml from fc.MexOpt contains COMPFLAGS=... /fixed ... that is
      % not wanted and breaks .F90 files. Removing this flags enables .F and .F90 to work
      % The user can do a one-time edit of this file to remove /fixed too.
      fcflags = sprintf('COMPFLAGS="%s"', strrep(fc.Details.CompilerFlags, '/fixed', ''));
    end
  end
end

plan("test:mex") = matlab.buildtool.tasks.TestTask(mexFolder + "/TestMex.m");

plan("clean") = matlab.buildtool.tasks.CleanTask;

%% MexTask
example_dir = fullfile(matlabroot, "extern/examples");
refbook = fullfile(example_dir, "refbook");

complex_api = "-R2018a";
% required "newer" interleaved interface, until it becomes default

plan("mex:matrixMultiply") = matlab.buildtool.tasks.MexTask(fullfile(refbook, "matrixMultiply.c"), mexFolder, ...
      Options=[complex_api, "-lmwblas"], Description="MEX C using BLAS");

plan("mex:arrayProduct") = matlab.buildtool.tasks.MexTask(fullfile(example_dir, "cpp_mex/arrayProduct.cpp"), mexFolder, ...
    Options=complex_api, Description="MEX C++");

if ~isempty(fc)

plan("mex:matsq") = matlab.buildtool.tasks.MexTask(fullfile(refbook, "matsq.F"), mexFolder, ...
    Options=complex_api, Description="MEX Fortran");

end

plan("test:mex").Dependencies = "mex";
%% engineTask
exe_ext = '';
if ispc(), exe_ext = '.exe'; end

plan("engine:c") = matlab.buildtool.Task(Inputs=fullfile(engFolder, 'c.c'), Actions=@(context) mex_engine(context, complex_api));
plan("engine:c").Outputs = plan("engine:c").Inputs.replace('.c', exe_ext);
plan("test:engine:c") = matlab.buildtool.Task(Inputs=plan("engine:c").Outputs, Actions=@subprocess_run, Dependencies="engine:c");

plan("engine:cpp") = matlab.buildtool.Task(Inputs=fullfile(engFolder, 'cpp.cpp'), Actions=@(context) mex_engine(context, complex_api));
plan("engine:cpp").Outputs = plan("engine:cpp").Inputs.replace('.cpp', exe_ext);
plan("test:engine:cpp") = matlab.buildtool.Task(Inputs=plan("engine:cpp").Outputs, Actions=@subprocess_run, Dependencies="engine:cpp");

if ~isempty(fc)
  plan("engine:fortran") = matlab.buildtool.Task(Inputs=fullfile(engFolder, 'fortran.F90'), Actions=@(context) mex_engine(context, [complex_api, fcflags]));
  plan("engine:fortran").Outputs = plan("engine:fortran").Inputs.replace('.F90', exe_ext);
  plan("test:engine:fortran") = matlab.buildtool.Task(Inputs=plan("engine:fortran").Outputs, Actions=@subprocess_run, Dependencies="engine:fortran");
end


%% Demonstrate using CMake
% this is not necessary for this project, but the concept might be useful
% for other projects

buildDir = fullfile(pwd(), "build-cmake");

plan("cmake:configure") = matlab.buildtool.Task(...
    Description="Configure CMake for the project", ...
    Actions=@(context) cmake_configure(context, buildDir));

plan("cmake:build") = matlab.buildtool.Task(...
    Description="Use CMake to build targets", ...
    Actions=@(context) cmake_build(context, buildDir), ...
    Dependencies="cmake:configure");

plan("cmake:test") = matlab.buildtool.Task(...
    Description="Use CTest to test targets", ...
    Actions=@(context) cmake_test(context, buildDir), ...
    Dependencies="cmake:build");

end


function cmake_configure(context, bindir)
cmd = sprintf('cmake -S%s -B%s', context.Plan.RootFolder, bindir);
s = system(cmd);

assert(s == 0)
end


function cmake_build(~, bindir)
cmd = sprintf('cmake --build %s', bindir);
s = system(cmd);

assert(s == 0)
end


function cmake_test(~, bindir)
cmd = sprintf('ctest --test-dir %s', bindir);
s = system(cmd);

assert(s == 0)
end


function checkTask(context)
root = context.Plan.RootFolder;

c = codeIssues(root, IncludeSubfolders=true);

if isempty(c.Issues)
  fprintf('%d files checked OK with %s under %s\n', numel(c.Files), c.Release, root)
else
  disp(c.Issues)
  error("Errors found in " + join(c.Issues.Location, newline))
end

end


function mex_engine(context, flags)
% There isn't yet a MexEngineTask built-in, and passing "-client engine" as
% MexTask options didn't work.
flags(~strlength(flags)) = [];
% add the "-v" option to the mex('-client', ...) command to get good debugging
mex("-client", "engine", context.Task.Inputs.paths, ...
    "-output", context.Task.Outputs(1).paths, ...
    flags{:})
end


function subprocess_run(context)

% sets env vars DYLD_LIBRARY_PATH, LD_LIBRARY_PATH, PATH, etc.
matlab_bin = fullfile(matlabroot, "bin");
mustBeFolder(matlab_bin)

matlab_extern_bin = fullfile(matlabroot, "extern/bin", computer("arch"));
mustBeFolder(matlab_extern_bin)

matlab_arch_bin = fullfile(matlab_bin, computer("arch"));
mustBeFolder(matlab_arch_bin)

newpath = join([matlab_bin, getenv("PATH")], pathsep);

envs = struct();
if ismac
  envs = struct(DYLD_LIBRARY_PATH=matlab_arch_bin, ...
                PATH=newpath);
elseif isunix
  linux_sys = fullfile(matlabroot, "sys/os", computer("arch"));

  envs = struct(...
      LD_LIBRARY_PATH=join([matlab_arch_bin, matlab_extern_bin, linux_sys], pathsep), ...
      PATH=newpath);
elseif ispc
  envs = struct(PATH=join([matlab_arch_bin, matlab_extern_bin, newpath], pathsep));
end
env = namedargs2cell(envs);

exe = context.Task.Inputs(1).paths;
[stat, msg] = system(exe, env{:});

assert(stat == 0, msg)
end
