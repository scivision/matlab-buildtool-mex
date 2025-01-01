// https://www.mathworks.com/help/matlab/matlab_external/pass-variables-from-c-to-matlab.html

#include "MatlabDataArray.hpp"
#include "MatlabEngine.hpp"

#include <iostream>
#include <cstdlib>

void diagnose(void)
{
    const char* envVars[] = { "LD_LIBRARY_PATH", "DYLD_LIBRARY_PATH", "PATH" };
    for (auto& envVar : envVars) {
        char* p = std::getenv(envVar);
        if (p)
            std::cout << envVar << ": " << p << "\n";
    }
}

int main() {
    using namespace matlab::engine;

    diagnose();

    //save startup time
    std::vector<String> optionVec;
    optionVec.push_back(u"-nojvm");

    // Start MATLAB engine synchronously
    std::unique_ptr<MATLABEngine> matlabPtr = startMATLAB(optionVec);

    //Create MATLAB data array factory
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
