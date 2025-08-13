#include "mex.hpp"
#include "mexAdapter.hpp"

#include <string>

#include <vector>
#include <memory>

#include "ffilesystem.h"


class MexFunction : public matlab::mex::Function {
private:
#include "mex1string.inl"

public:
  void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {

    matlab::data::ArrayFactory factory;

// convert to Matlab output
// https://www.mathworks.com/help/matlab/matlab_external/create-matlab-array-with-matlab-data-cpp-api.html
// https://www.mathworks.com/help/matlab/apiref/matlab.data.arrayfactory.html

    outputs[0] = factory.createScalar<bool>(fs_is_symlink(matlab_1string_input(inputs)));
  }
};
