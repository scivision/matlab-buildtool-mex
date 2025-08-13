#include "mex.hpp"
#include "mexAdapter.hpp"

#include <string>
#include <string_view>

#include <vector>
#include <memory>

#include <cstdint>
#include <filesystem>
#include <system_error>


class MexFunction : public matlab::mex::Function {
private:
#include "mex1string.inl"

public:
  void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {

    matlab::data::ArrayFactory factory;

    std::error_code ec;
    std::uintmax_t s = std::filesystem::space(matlab_1string_input(inputs), ec).available;

    if (ec)
      s = 0;

    outputs[0] = factory.createScalar(s);
  }
};
