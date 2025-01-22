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
%% engineTask

engs = [...
fullfile(plan.RootFolder, "engine/Cengine.c"), ""; ...
fullfile(plan.RootFolder, "engine/CppEngine.cpp"), ""; ...
];

if ~isempty(fc)
  engs(end+1,:) = [fullfile(plan.RootFolder, "engine/eng_demo.F90"), ""];
end

for i = 1:size(engs, 1)
  src = engs(i, 1);
  [~, name] = fileparts(src);
  eng_name = "engine:" + name;

  plan(eng_name) = matlab.buildtool.Task(...
      Actions=@(context) mex_engine(context, src, bindir, ...
      [complex_api, engs(i, 2)]));
  % allow incremental builds
  plan(eng_name).Inputs = src;
  exe = fullfile(bindir, name);
  if ispc, exe = exe + ".exe"; end
  plan(eng_name).Outputs = exe;

  plan("test:engine:" + name) = matlab.buildtool.Task(...
      Actions=@(context) subprocess_run(context, exe));
end

end


function mex_engine(~, src, bindir, flags)
flags(~strlength(flags)) = [];
mex("-client", "engine", src, "-outdir", bindir, flags)
end


function subprocess_run(~, exe)

matlab_bin = fullfile(matlabroot, "bin");
mustBeFolder(matlab_bin)

matlab_extern_bin = fullfile(matlabroot, "extern/bin", computer("arch"));
mustBeFolder(matlab_extern_bin)

matlab_arch_bin = fullfile(matlab_bin, computer("arch"));
mustBeFolder(matlab_arch_bin)

envs = struct();
if ismac
  envs = struct(DYLD_LIBRARY_PATH=matlab_arch_bin, PATH=matlab_bin);
elseif isunix
  linux_sys = fullfile(matlabroot, "sys/os", computer("arch"));
  envs = struct(LD_LIBRARY_PATH=matlab_arch_bin + pathsep + matlab_extern_bin + pathsep + linux_sys, ...
                PATH=matlab_bin);
elseif ispc
  envs = struct(PATH=matlab_arch_bin + pathsep + matlab_extern_bin + pathsep + matlab_bin);
end
env = namedargs2cell(envs);

[stat, msg] = system(exe, env{:});

assert(stat == 0, msg)
end