#include "mex.hpp"
#include "mexAdapter.hpp"

#include <vector>
#include <memory>

#include <filesystem>
#include <system_error>


class MexFunction : public matlab::mex::Function {
private:
#include "mex1string.inl"

public:
  void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {

    matlab::data::ArrayFactory factory;

    std::error_code ec;
    bool y = std::filesystem::remove(matlab_1string_input(inputs), ec) && !ec;

    outputs[0] = factory.createScalar<bool>(y);
  }
};
