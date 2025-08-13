#include "mex.hpp"
#include "mexAdapter.hpp"

#include <vector>
#include <memory>

#include "ffilesystem.h"


class MexFunction : public matlab::mex::Function {
private:
#include "mex0.inl"

public:
  void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {

    matlab_0_input(inputs);

    matlab::data::ArrayFactory factory;

    outputs[0] = factory.createScalar<int>(fs_is_wsl());
  }
};
