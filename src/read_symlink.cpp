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

    std::string p = fs_read_symlink(matlab_1string_input(inputs));

    if (p.empty()) {
      outputs[0] = factory.createArray<matlab::data::MATLABString>({0, 0});
    } else {
      outputs[0] = factory.createScalar(p);
    }
  }
};
