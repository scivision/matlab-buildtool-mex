void matlab_0_input(matlab::mex::ArgumentList inputs)
{
    std::shared_ptr<matlab::engine::MATLABEngine> matlabEng = getEngine();

    matlab::data::ArrayFactory factory;

    if (inputs.size() != 0) {
      matlabEng->feval(u"error", 0,
        std::vector<matlab::data::Array>({ factory.createScalar("MexFunction requires exactly zero inputs.") }));
    }
}
