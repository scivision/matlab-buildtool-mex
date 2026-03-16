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

plan("clean") = matlab.buildtool.tasks.CleanTask();

%% MexTask
example_dir = fullfile(matlabroot, "extern/examples");
refbook = fullfile(example_dir, "refbook");

complex_api = "-R2018a";
% required "newer" interleaved interface, until it becomes default

plan("mex:matrixMultiply") = matlab.buildtool.tasks.MexTask(fullfile(refbook, "matrixMultiply.c"), mexFolder, ...
      Options=[complex_api, "-lmwblas"], Description="MEX C using BLAS");

plan("mex:arrayProduct") = matlab.buildtool.tasks.MexTask(fullfile(example_dir, "cpp_mex/arrayProduct.cpp"), mexFolder, ...
    Options=complex_api, Description="MEX C++");

tags = "cpp";
if ~isempty(fc)
  plan("mex:matsq") = matlab.buildtool.tasks.MexTask(fullfile(refbook, "matsq.F"), mexFolder, ...
      Options=complex_api, Description="MEX Fortran");
  tags = [tags, "fortran"];
end

plan("test:mex") = matlab.buildtool.tasks.TestTask(mexFolder + "/TestMex.m", Dependencies="mex", Tag=tags);
%% engineTask
exe_ext = '';
if ispc()
  exe_ext = '.exe';
  % mex -output ignores .exe extension on non-Windows
end

engine_flags = [complex_api, "-v"];

plan("engine:c") = matlab.buildtool.Task(...
  Inputs=fullfile(engFolder, ["c_demo.c", "env_diagnose.c"]), ...
  Actions=@(context) mex_engine(context, engine_flags));

plan("engine:c").Outputs = plan("engine:c").Inputs(1).replace('.c', exe_ext);

plan("engine:cpp") = matlab.buildtool.Task(...
  Inputs=fullfile(engFolder, ["cpp_demo.cpp", "env_diagnose.c"]), ...
  Actions=@(context) mex_engine(context, engine_flags));

plan("engine:cpp").Outputs = plan("engine:cpp").Inputs(1).replace('.cpp', exe_ext);

if ~isempty(fc)
  plan("engine:fortran") = matlab.buildtool.Task(...
    Inputs=fullfile(engFolder, 'fortran_demo.F90'), ...
    Actions=@(context) mex_engine(context, [engine_flags, fcflags]));

  plan("engine:fortran").Outputs = plan("engine:fortran").Inputs.replace('.F90', exe_ext);
end

plan("test:engine") = matlab.buildtool.Task(Inputs=[plan("engine").Tasks.Outputs], Dependencies="engine", Action=@engine_test);


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

mex("-client", "engine", context.Task.Inputs.paths{:}, ...
    "-output", context.Task.Outputs.paths, ...
    flags{:})
end


function engine_test(context)

[~, names] = fileparts(context.Task.Inputs.paths);
if ispc
  names = names + ".exe";
end

param = matlab.unittest.parameters.Parameter.fromData("exe", cellstr(names));

suite = matlab.unittest.TestSuite.fromFile(context.Plan.RootFolder + "/engine/TestEngine.m", ...
          ExternalParameters=param);

runner = matlab.unittest.TestRunner.withTextOutput;
r = runner.run(suite);

assertSuccess(r);

end
