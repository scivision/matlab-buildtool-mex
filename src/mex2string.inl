void matlab_2string(matlab::mex::ArgumentList inputs, std::string* s1, std::string* s2)
  {
    std::shared_ptr<matlab::engine::MATLABEngine> matlabEng = getEngine();

    matlab::data::ArrayFactory factory;

    if (inputs.size() != 2) {
      matlabEng->feval(u"error", 0,
        std::vector<matlab::data::Array>({ factory.createScalar("Mex: Two inputs required") }));
    }

    if ((inputs[0].getType() == matlab::data::ArrayType::MATLAB_STRING && inputs[0].getNumberOfElements() == 1)){
        matlab::data::TypedArray<matlab::data::MATLABString> stringArr = inputs[0];
        *s1 = stringArr[0];
    } else if (inputs[0].getType() == matlab::data::ArrayType::CHAR){
        matlab::data::CharArray charArr = inputs[0];
        *s1 = std::string(charArr.begin(), charArr.end());
    } else {
        matlabEng->feval(u"error", 0,
        std::vector<matlab::data::Array>({ factory.createScalar("Mex: First input must be a scalar string or char vector") }));
    }

     if ((inputs[1].getType() == matlab::data::ArrayType::MATLAB_STRING && inputs[1].getNumberOfElements() == 1)){
        matlab::data::TypedArray<matlab::data::MATLABString> stringArr = inputs[1];
        *s2 = stringArr[0];
    } else if (inputs[1].getType() == matlab::data::ArrayType::CHAR){
        matlab::data::CharArray charArr = inputs[1];
        *s2 = std::string(charArr.begin(), charArr.end());
    } else {
        matlabEng->feval(u"error", 0,
        std::vector<matlab::data::Array>({ factory.createScalar("Mex: Second input must be a scalar string or char vector") }));
    }
  }
