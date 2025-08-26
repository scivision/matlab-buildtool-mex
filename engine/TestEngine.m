classdef (SharedTestFixtures={ matlab.unittest.fixtures.PathFixture(".")}) ...
  TestEngine < matlab.unittest.TestCase

properties (TestParameter)
exe = {"c.exe", "cpp.exe", "fortran.exe"}
end

methods (TestClassSetup)
function setup_env(tc)
import matlab.unittest.constraints.IsFolder

% sets env vars DYLD_LIBRARY_PATH, LD_LIBRARY_PATH, PATH, etc.
matlab_bin = fullfile(matlabroot, "bin");
tc.assertThat(matlab_bin, IsFolder)

matlab_extern_bin = fullfile(matlabroot, "extern/bin", computer("arch"));
tc.assertThat(matlab_extern_bin, IsFolder)

matlab_arch_bin = fullfile(matlab_bin, computer("arch"));
tc.assertThat(matlab_arch_bin, IsFolder)

newpath = join([matlab_bin, getenv("PATH")], pathsep);

envs = dictionary(PATH=newpath);
if ismac
  envs("DYLD_LIBRARY_PATH") = matlab_arch_bin;
elseif isunix
  linux_sys = fullfile(matlabroot, "sys/os", computer("arch"));

  envs("LD_LIBRARY_PATH") = join([matlab_arch_bin, matlab_extern_bin, linux_sys], pathsep);
elseif ispc
  envs("PATH") = join([matlab_arch_bin, matlab_extern_bin, newpath], pathsep);
end

fx = matlab.unittest.fixtures.EnvironmentVariableFixture(envs.keys, envs.values);
tc.applyFixture(fx)
end
end


methods (Test)

function test_engine_run(tc, exe)
  import matlab.unittest.constraints.IsFile
  tc.assumeThat(exe, IsFile)

  [stat, msg] = system(exe);
  tc.verifyEqual(stat, 0, msg)
end

end
end
