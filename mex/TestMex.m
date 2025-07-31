classdef TestMex < matlab.unittest.TestCase

methods(TestClassSetup)
function pkg_path(tc)
p = matlab.unittest.fixtures.PathFixture(fileparts(mfilename('fullpath')));
tc.applyFixture(p)
end
end

methods(Test)

function test_blas(tc)

a = eye(3);
b = magic(3);

try
  x = matrixMultiply(a, b);
catch excp
  assumer(tc, excp)
end

tc.verifyEqual(x, a*b)
end

function test_cpp_array(tc)

a = eye(3);

try
  x = arrayProduct(2, a);
catch excp
  assumer(tc, excp)
end

tc.verifyEqual(x, 2*a)
end

function test_fortran_mex(tc)

a = eye(3);

try
  x = matsq(a);
catch excp
  assumer(tc, excp)
end

tc.verifyEqual(x, a.^2)

end

end

end
