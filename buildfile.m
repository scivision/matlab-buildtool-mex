function plan = buildfile
assert(~isMATLABReleaseOlderThan("R2024b"))

plan = buildplan();

plan.DefaultTasks = "test";

bindir = fullfile(tempdir, "build-mex-engine-" + matlabRelease().Release);
if ~isfolder(bindir), mkdir(bindir); end

plan("check") = matlab.buildtool.tasks.CodeIssuesTask(".", IncludeSubfolders=true, ...
    WarningThreshold=0);
    % Results="code-issues.sarif");

fc = mex.getCompilerConfigurations('fortran');

addpath(bindir, plan.RootFolder + "/mex")

plan("test:mex:blas") = matlab.buildtool.tasks.TestTask("TestMex/test_blas");
plan("test:mex:array") = matlab.buildtool.tasks.TestTask("TestMex/test_cpp_array");
if ~isempty(fc)
plan("test:mex:fortran") = matlab.buildtool.tasks.TestTask("TestMex/test_fortran_mex");
end

plan("clean") = matlab.buildtool.tasks.CleanTask;

%% MexTask
example_dir = fullfile(matlabroot, "extern/examples");
refbook = fullfile(example_dir, "refbook");

mexs = [...
fullfile(refbook, "matrixMultiply.c"), "-lmwblas"; ...
fullfile(example_dir, "cpp_mex/arrayProduct.cpp"), ""; ...
];

if ~isempty(fc)
  mexs(end+1,:) = [fullfile(refbook, "matsq.F"), ""];
end

complex_api = "-R2018a";
% required "newer" interleaved interface, until it becomes default

for i = 1:size(mexs, 1)
  src = mexs(i, 1);
  [~, name] = fileparts(src);

  plan("mex:" + name) = matlab.buildtool.tasks.MexTask(src, bindir, ...
      Options=[complex_api, mexs(i, 2)]);
end

plan("test:mex").Dependencies = "mex";
%% engineTask

engs = [...
fullfile(plan.RootFolder, "engine/Cengine.c"), ""; ...
fullfile(plan.RootFolder, "engine/CppEngine.cpp"), ""; ...
];

if ~isempty(fc)
  engs(end+1,:) = [fullfile(plan.RootFolder, "engine/FortranEngine.F90"), ""];
end

for i = 1:size(engs, 1)
  src = engs(i, 1);
  [~, name] = fileparts(src);
  eng_name = "engine:" + name;
  exe = fullfile(bindir, name);
  if ispc, exe = exe + ".exe"; end

  plan(eng_name) = matlab.buildtool.Task(Inputs=src, ...
      Outputs=exe, ...
      Actions=@(context) mex_engine(context, src, bindir, ...
      [complex_api, engs(i, 2)]));

  plan("test:engine:" + name) = matlab.buildtool.Task(...
      Actions=@(context) subprocess_run(context, exe));
end

plan("test:engine").Dependencies = "engine";

end


function mex_engine(~, src, bindir, flags)
% There isn't yet a MexEngineTask built-in, and passing "-client engine" as
% MexTask options didn't work.
flags(~strlength(flags)) = [];
mex("-client", "engine", src, "-outdir", bindir, flags)
end


function subprocess_run(~, exe)

% sets env vars DYLD_LIBRARY_PATH, LD_LIBRARY_PATH, PATH, etc.
matlab_bin = fullfile(matlabroot, "bin");
mustBeFolder(matlab_bin)

matlab_extern_bin = fullfile(matlabroot, "extern/bin", computer("arch"));
mustBeFolder(matlab_extern_bin)

matlab_arch_bin = fullfile(matlab_bin, computer("arch"));
mustBeFolder(matlab_arch_bin)

newpath = matlab_bin + pathsep + getenv("PATH");

envs = struct();
if ismac
  envs = struct(DYLD_LIBRARY_PATH=matlab_arch_bin, ...
                PATH=newpath);
elseif isunix
  linux_sys = fullfile(matlabroot, "sys/os", computer("arch"));

  envs = struct(...
      LD_LIBRARY_PATH=matlab_arch_bin + pathsep + matlab_extern_bin + pathsep + linux_sys, ...
      PATH=newpath);
elseif ispc
  envs = struct(PATH=matlab_arch_bin + pathsep + matlab_extern_bin + pathsep + newpath);
end
env = namedargs2cell(envs);

[stat, msg] = system(exe, env{:});

assert(stat == 0, msg)
end
