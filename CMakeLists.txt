cmake_minimum_required(VERSION 3.22...4.4)
# 3.22 ENVIRONMENT_MODIFICATION and FindMatlab new targets

if(CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)
  message(FATAL_ERROR "In-source builds are not allowed. Do like:
  cmake -B build
  cmake --build build")
endif()

project(MatlabMEX LANGUAGES NONE)

enable_testing()

set(eng_method "wrap")
set(mex_method "wrap")
# note that find, the FindMatlab matlab_add_mex() method is broken generally. Consider buildtool instead.

if(eng_method STREQUAL "find" OR mex_method STREQUAL "find")
  enable_language(C)
  enable_language(CXX)
  enable_language(Fortran)
endif()

if(NOT mex_method MATCHES "wrap|find")
  message(FATAL_ERROR "Invalid Matlab MEX build method: ${mex_method}")
endif()
if(NOT eng_method MATCHES "cmake|find|wrap")
  message(FATAL_ERROR "Invalid Matlab Engine build method: ${eng_method}")
endif()

message(STATUS "CMake ${CMAKE_VERSION}. build methods - engine: ${eng_method} mex: ${mex_method}")

# set(MATLAB_FIND_DEBUG true)

file(GENERATE OUTPUT .gitignore CONTENT "*")

find_package(Matlab COMPONENTS MAIN_PROGRAM MEX_COMPILER REQUIRED) # ENG_LIBRARY MAT_LIBRARY MX_LIBRARY
if(CMAKE_VERSION VERSION_LESS 3.27)
  set(Matlab_VERSION ${Matlab_VERSION_STRING})
endif()

# --- Matlab paths and libs
include(cmake/matlab.cmake)

# --- Mex example
add_subdirectory(mex)

# --- Matlab Engine examples: C, C++, Fortran
add_subdirectory(engine)


include(FeatureSummary)

add_feature_info(Matlab_mex_Fortran Matlab_mex_Fortran "Matlab Fortran MEX")


feature_summary(WHAT ENABLED_FEATURES DISABLED_FEATURES)
