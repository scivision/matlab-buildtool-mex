function plan = buildfile
assert(~isMATLABReleaseOlderThan("R2024b"))

plan = buildplan();

plan.DefaultTasks = "test";

bindir = fullfile(tempdir, "build-mex-engine-" + matlabRelease().Release);
if ~isfolder(bindir), mkdir(bindir); end

plan("check") = matlab.buildtool.tasks.CodeIssuesTask(".", IncludeSubfolders=true, ...
    WarningThreshold=0);
    % Results="code-issues.sarif");

addpath(bindir, plan.RootFolder + "/mex")

plan("test:mex:blas") = matlab.buildtool.tasks.TestTask("TestMex/test_blas");
plan("test:mex:array") = matlab.buildtool.tasks.TestTask("TestMex/test_cpp_array");
plan("test:mex:fortran") = matlab.buildtool.tasks.TestTask("TestMex/test_fortran_mex");

plan("clean") = matlab.buildtool.tasks.CleanTask;

%% MexTask
example_dir = fullfile(matlabroot, "extern/examples");

mexs = [...
fullfile(example_dir, "refbook/matrixMultiply.c"), "-lmwblas"; ...
fullfile(example_dir, "cpp_mex/arrayProduct.cpp"), ""; ...
];

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

fc = mex.getCompilerConfigurations('fortran');
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

  %plan("test:" + name) =
end

end


function mex_engine(~, src, bindir, flags)
flags(~strlength(flags)) = [];
mex("-client", "engine", src, "-outdir", bindir, flags)
end
