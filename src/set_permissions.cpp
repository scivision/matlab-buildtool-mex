#include "mex.hpp"
#include "mexAdapter.hpp"

#include <string>
#include <string_view>

#include <vector>
#include <memory>

#include <filesystem>
#include <system_error>


static bool fs_set_permissions(std::string_view path, int readable, int writable, int executable)
{

#if defined(__cpp_using_enum)  // C++20
  using enum std::filesystem::perms;
#else
  constexpr std::filesystem::perms owner_read = std::filesystem::perms::owner_read;
  constexpr std::filesystem::perms owner_write = std::filesystem::perms::owner_write;
  constexpr std::filesystem::perms owner_exec = std::filesystem::perms::owner_exec;
#endif

  std::filesystem::path p(path);
  std::error_code ec;
  // need to error if path doesn't exist and no operations are requested
  if(!std::filesystem::exists(p))
    ec = std::make_error_code(std::errc::no_such_file_or_directory);

  if (!ec && readable != 0)
    std::filesystem::permissions(p, owner_read,
      (readable > 0) ? std::filesystem::perm_options::add : std::filesystem::perm_options::remove,
      ec);

  if (!ec && writable != 0)
    std::filesystem::permissions(p, owner_write,
      (writable > 0) ? std::filesystem::perm_options::add : std::filesystem::perm_options::remove,
      ec);

  if (!ec && executable != 0)
    std::filesystem::permissions(p, owner_exec,
      (executable > 0) ? std::filesystem::perm_options::add : std::filesystem::perm_options::remove,
      ec);

  return !ec;
}



class MexFunction : public matlab::mex::Function {
public:
  void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
// boilerplate engine & ArrayFactory setup
    std::shared_ptr<matlab::engine::MATLABEngine> matlabEng = getEngine();

    matlab::data::ArrayFactory factory;
// wrangle inputs
    std::string in;

    if (inputs.size() != 4) {
      matlabEng->feval(u"error", 0,
        std::vector<matlab::data::Array>({ factory.createScalar("Mex: Four inputs required") }));
    }
    if ((inputs[0].getType() == matlab::data::ArrayType::MATLAB_STRING && inputs[0].getNumberOfElements() == 1)){
        matlab::data::TypedArray<matlab::data::MATLABString> stringArr = inputs[0];
        in = stringArr[0];
    } else if (inputs[0].getType() == matlab::data::ArrayType::CHAR){
        matlab::data::CharArray charArr = inputs[0];
        in.assign(charArr.begin(), charArr.end());
    } else {
        matlabEng->feval(u"error", 0,
        std::vector<matlab::data::Array>({ factory.createScalar("Mex: First input must be a scalar string or char vector") }));
    }
    if (inputs[1].getType() != matlab::data::ArrayType::DOUBLE ||
        inputs[2].getType() != matlab::data::ArrayType::DOUBLE ||
        inputs[3].getType() != matlab::data::ArrayType::DOUBLE) {
      matlabEng->feval(u"error", 0,
        std::vector<matlab::data::Array>({ factory.createScalar("Mex: Permission inputs must be scalar doubles") }));
    }

// actual function algorithm / computation
    bool y = fs_set_permissions(in, inputs[1][0], inputs[2][0], inputs[3][0]);

// convert to Matlab output
// https://www.mathworks.com/help/matlab/matlab_external/create-matlab-array-with-matlab-data-cpp-api.html
// https://www.mathworks.com/help/matlab/apiref/matlab.data.arrayfactory.html

    if (!y) {
      matlabEng->feval(u"error", 0,
        std::vector<matlab::data::Array>({ factory.createScalar("Mex: Failed to set permissions") }));
    }
  }
};
