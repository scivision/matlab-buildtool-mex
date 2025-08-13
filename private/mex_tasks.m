function mex_tasks(context)

pkg_root = fullfile(context.Plan.RootFolder, "+stdlib");
test_root = fullfile(context.Plan.RootFolder, "test");

if ~isMATLABReleaseOlderThan("R2024b")


for s = get_mex_sources()
  src = s{1};
  [~, name] = fileparts(src(1));

% name of MEX target function is name of first source file
  context.Plan("mex:" + name) = matlab.buildtool.tasks.MexTask(src, pkg_root, ...
    Description="Build MEX target " + name, ...
    Options=get_compiler_options());
end

end

context.Plan("clean_mex") = matlab.buildtool.Task(Actions=@clean_mex, Description="Clean only MEX files to enable incremental tests");

if isMATLABReleaseOlderThan('R2025a')
  % plan("test:mex")   = matlab.buildtool.Task(Actions=@(context) test_main(context, cmex), Dependencies="mex");
  
  context.Plan("test:mex") = matlab.buildtool.tasks.TestTask(...
     test_root, Description="Test mex targts",...
     Tag="mex", ...
     Dependencies="mex", TestResults="TestResults_mex.xml", Strict=true);
else
  context.Plan("test:mex") = matlab.buildtool.tasks.TestTask(...
     test_root, Description="Test mex targts",...
     Tag="mex", ...
     SourceFiles=[pkg_root, context.Plan.RootFolder + "/src"], RunOnlyImpactedTests=true,...
     Dependencies="mex", TestResults="TestResults_mex.xml", Strict=true);
end

end
