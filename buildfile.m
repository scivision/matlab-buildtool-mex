function plan = buildfile
assert(~isMATLABReleaseOlderThan("R2024b"))

plan = buildplan();

plan.DefaultTasks = "test";


mexFolder = plan.RootFolder + "/mex";
engFolder = plan.RootFolder + "/engine";

plan("check") = matlab.buildtool.tasks.CodeIssuesTask(".", IncludeSubfolders=true, ...
    WarningThreshold=0);
    % Results="code-issues.sarif");

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

engs = [...
fullfile(plan.RootFolder, "engine/c.c"), ""; ...
fullfile(plan.RootFolder, "engine/cpp.cpp"), ""; ...
];

if ~isempty(fc)
  engs(end+1,:) = [fullfile(plan.RootFolder, "engine/fortran.F90"), fcflags];
end

for i = 1:size(engs, 1)
  src = engs(i, 1);
  [~, name] = fileparts(src);
  eng_name = "engine:" + name;
  exe = fullfile(engFolder, name);
  if ispc, exe = exe + ".exe"; end

  plan(eng_name) = matlab.buildtool.Task(Inputs=src, ...
      Outputs=exe, ...
      Actions=@(context) mex_engine(context, src, engFolder, [complex_api, engs(i, 2)]));

  plan("test:engine:" + name) = matlab.buildtool.Task(...
      Actions=@(context) subprocess_run(context, exe));
end

plan("test:engine").Dependencies = "engine";

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

function mex_engine(~, src, bindir, flags)
% There isn't yet a MexEngineTask built-in, and passing "-client engine" as
% MexTask options didn't work.
flags(~strlength(flags)) = [];
% add the "-v" option to the mex('-client', ...) command to get good debugging
mex("-client", "engine", src, "-outdir", bindir, flags{:})
end


function subprocess_run(~, exe)

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

[stat, msg] = system(exe, env{:});

assert(stat == 0, msg)
end
