function plan = buildfile
assert(~isMATLABReleaseOlderThan("R2023b"))

plan = buildplan();

plan.DefaultTasks = "test";

bindir = fullfile(tempdir, "build-mex-engine-" + matlabRelease().Release);
if ~isfolder(bindir), mkdir(bindir); end

plan("check") = matlab.buildtool.tasks.CodeIssuesTask(".", IncludeSubfolders=true, ...
    WarningThreshold=0);
    % Results="code-issues.sarif");

addpath(bindir)

plan("test") = matlab.buildtool.tasks.TestTask(...
    fullfile(plan.RootFolder, "mex"), Strict=false);

plan("clean") = matlab.buildtool.tasks.CleanTask;

if isMATLABReleaseOlderThan("R2024b"), return, end
%% MexTask
example_dir = fullfile(matlabroot, "extern/examples");

mexs = [...
fullfile(example_dir, "refbook/matrixMultiply.c"), "-lmwblas"; ...
fullfile(example_dir, "cpp_mex/arrayProduct.cpp"), ""; ...
];


for i = 1:size(mexs, 1)
  src = mexs(i, 1);
  [~, name] = fileparts(src);

  plan("mex:" + name) = matlab.buildtool.tasks.MexTask(src, bindir, Options=mexs(i, 2));
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
      Actions=@(context) mex_engine(context, src, bindir, engs(i, 2)));
  % allow incremental builds
  plan(eng_name).Inputs = src;
  plan(eng_name).Outputs = fullfile(bindir, name);

  %plan("test:" + name) =
end

end


% function legacy_mex(context, src, flags, bindir)
% mex(src, "-outdir", bindir, flags{:});
% end

function mex_engine(~, src, bindir, flags)
mex("-client", "engine", src, "-outdir", bindir, flags, "-v")
end
