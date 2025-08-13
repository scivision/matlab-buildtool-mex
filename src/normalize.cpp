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

    outputs[0] = factory.createScalar(fs_normalize(matlab_1string_input(inputs)));
  }
};
