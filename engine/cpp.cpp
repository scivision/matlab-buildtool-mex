// https://www.mathworks.com/help/matlab/matlab_external/pass-variables-from-c-to-matlab.html

#include "MatlabDataArray.hpp"
#include "MatlabEngine.hpp"

#include <iostream>
#include <cstdlib>
#include <string>

#include <memory>
#include <vector>

void diagnose(void)
{
  std::string reqEnv;
  char* r;

#ifdef __APPLE__
  reqEnv = "DYLD_dummy_LIBRARY_PATH";  // dummy name to bypass macOS security
  r = std::getenv(reqEnv.data());
  if (!r){
    std::cerr << "C++ exe: workaround environment variable " << reqEnv << " not set, run will fail, aborting...\n";
    std::exit(77);
  }
  reqEnv = "DYLD_LIBRARY_PATH";
  if(::setenv(reqEnv.data(), r, 1) != 0){
    std::cerr << "C++ exe: error setting environment variable " << reqEnv << "\n";
    std::exit(77);
  }
#elif defined(__linux__)
  reqEnv = "LD_LIBRARY_PATH";
#elif defined(_WIN32)
  reqEnv = "PATH";
#endif


#ifndef _WIN32
  r = std::getenv("PATH");
  if (r)
    std::cout << "PATH: " << r << "\n";
#endif

    r = std::getenv(reqEnv.data());
    if (!r){
      std::cerr << "C++ exe: environment variable " << reqEnv << " not set, run will fail, aborting...\n";
      std::exit(77);
    }

    std::cout << reqEnv << ": " << r << "\n";

}

int main() {

    diagnose();

    //save startup time for Matlab < R2025a
    std::vector<matlab::engine::String> optionVec;
    optionVec.push_back(u"-nojvm");

    std::cout << "Start MATLAB engine synchronously" << std::endl;
    std::unique_ptr<matlab::engine::MATLABEngine> matlabPtr =
        matlab::engine::startMATLAB(optionVec);

    std::cout << "Create MATLAB data array factory" << std::endl;
    // https://www.mathworks.com/help/matlab/matlab-data-array.html
    matlab::data::ArrayFactory factory;

    // Create variables
    matlab::data::TypedArray<double> data = factory.createArray<double>({ 1, 10 },
        { 4, 8, 6, -1, -2, -3, -1, 3, 4, 5 });
    matlab::data::TypedArray<int32_t>  windowLength = factory.createScalar<int32_t>(3);
    matlab::data::CharArray name = factory.createCharArray("Endpoints");
    matlab::data::CharArray value = factory.createCharArray("discard");

    // Put variables in the MATLAB workspace
    matlabPtr->setVariable(u"data", std::move(data));
    matlabPtr->setVariable(u"w", std::move(windowLength));
    matlabPtr->setVariable(u"n", std::move(name));
    matlabPtr->setVariable(u"v", std::move(value));

    // Call the MATLAB movsum function
    matlabPtr->eval(u"A = movsum(data, w, n, v);");

    // Get the result
    matlab::data::TypedArray<double> const A = matlabPtr->getVariable(u"A");

    // Terminate MATLAB session -- this made Matlab hang
    //matlab::engine::terminateEngineClient();

    // Display the result
    int i = 0;
    for (auto r : A) {
        std::cout << "results[" << i << "] = " << r << "\n";
        ++i;
    }

    return EXIT_SUCCESS;
}

void mexFunction(int nlhs, matlab::data::Array *plhs[], int nrhs, const matlab::data::Array *prhs[]){}
/* https://www.mathworks.com/help/matlab/matlab_external/symbol-mexfunction-unresolved-or-not-defined.html */
