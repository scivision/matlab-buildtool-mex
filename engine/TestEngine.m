classdef (SharedTestFixtures={ matlab.unittest.fixtures.PathFixture(".")}) ...
  TestEngine < matlab.unittest.TestCase

properties
cwd
envs
end

properties (TestParameter)
exe = {"c", "cpp", "fortran"}
end

methods (TestClassSetup)
function setup_env(tc)
import matlab.unittest.constraints.IsFolder

tc.cwd = fileparts(mfilename("fullpath"));

% sets env vars DYLD_LIBRARY_PATH, LD_LIBRARY_PATH, PATH, etc.
matlab_bin = fullfile(matlabroot, "bin");
tc.assertThat(matlab_bin, IsFolder)

matlab_extern_bin = fullfile(matlabroot, "extern/bin", computer("arch"));
tc.assertThat(matlab_extern_bin, IsFolder)

matlab_arch_bin = fullfile(matlab_bin, computer("arch"));
tc.assertThat(matlab_arch_bin, IsFolder)

newpath = join([matlab_bin, getenv("PATH")], pathsep);

tc.envs = dictionary(PATH=newpath);
if ismac
  tc.envs("dummy_LIBRARY_PATH") = matlab_arch_bin;
elseif isunix
  linux_sys = fullfile(matlabroot, "sys/os", computer("arch"));

  tc.envs("LD_LIBRARY_PATH") = join([matlab_arch_bin, matlab_extern_bin, linux_sys], pathsep);
elseif ispc
  tc.envs("PATH") = join([matlab_arch_bin, matlab_extern_bin, newpath], pathsep);
end

% no, the env var need to be applied in system() call
% for k = keys(envs).'
%   fx = matlab.unittest.fixtures.EnvironmentVariableFixture(k, envs(k));
%   tc.applyFixture(fx)
% end

end

end


methods (Test)

function test_engine_run(tc, exe)

  exe = fullfile(tc.cwd, exe);
  tc.assumeThat(exe, matlab.unittest.constraints.IsFile, "test executable " + exe + " not found, skipping test")

% convert dictionary of env vars to name,value string array for system call
keys = cellstr(tc.envs.keys);
vals = cellstr(tc.envs.values);
envCell = reshape([keys(:).'; vals(:).'], 1, []);

% disp("Applying environment varables to " + exe)
% disp(envCell)
[stat, msg] = system(exe, envCell{:});

  tc.verifyEqual(stat, 0, msg)
end

end
end
