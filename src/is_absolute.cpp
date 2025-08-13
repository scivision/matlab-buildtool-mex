#include "mex.hpp"
#include "mexAdapter.hpp"

#include <vector>
#include <memory>

#include "ffilesystem.h"

#include <filesystem>


class MexFunction : public matlab::mex::Function {
private:
#include "mex1string.inl"

public:
  void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {

    std::filesystem::path p(matlab_1string_input(inputs));

    matlab::data::ArrayFactory factory;

    outputs[0] = factory.createScalar<bool>(p.is_absolute());
  }
};
