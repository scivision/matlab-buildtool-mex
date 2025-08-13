#include "mex.hpp"
#include "mexAdapter.hpp"

#include <string>

#include <vector>
#include <memory>

#include <system_error>
#include <filesystem>

#include "ffilesystem.h"


class MexFunction : public matlab::mex::Function {
private:
#include "mex2string.inl"

public:
  void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {

    std::shared_ptr<matlab::engine::MATLABEngine> matlabEng = getEngine();

    matlab::data::ArrayFactory factory;

    std::string base, other;

    matlab_2string(inputs, &base, &other);

    std::error_code ec;
    std::string out = std::filesystem::relative(other, base, ec).string();

    if(ec)
      matlabEng->feval(u"error", 0,
        std::vector<matlab::data::Array>({ factory.createScalar(ec.message()) }));

    outputs[0] = factory.createScalar(out);
  }
};
