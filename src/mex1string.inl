  std::string matlab_1string_input(matlab::mex::ArgumentList inputs)
  {
    std::shared_ptr<matlab::engine::MATLABEngine> matlabEng = getEngine();

    matlab::data::ArrayFactory factory;
    std::string in;

    if (inputs.size() != 1) {
      matlabEng->feval(u"error", 0,
        std::vector<matlab::data::Array>({ factory.createScalar("MexFunction requires exactly one scalar input argument") }));
    }
    if ((inputs[0].getType() == matlab::data::ArrayType::MATLAB_STRING && inputs[0].getNumberOfElements() == 1)){
        matlab::data::TypedArray<matlab::data::MATLABString> stringArr = inputs[0];
        in = stringArr[0];
    } else if (inputs[0].getType() == matlab::data::ArrayType::CHAR){
        matlab::data::CharArray charArr = inputs[0];
        in.assign(charArr.begin(), charArr.end());
    } else {
        matlabEng->feval(u"error", 0,
          std::vector<matlab::data::Array>({ factory.createScalar("MexFunction: First input must be a scalar string or char vector") }));
    }

    return in;
  }
