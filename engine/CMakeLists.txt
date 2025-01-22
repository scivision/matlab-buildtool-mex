set_property(DIRECTORY PROPERTY LABELS "engine")

# --- C calling Matlab Engine

if(Matlab_engine_C)

add_executable(engine_c Cengine.c)
target_link_libraries(engine_c PRIVATE Matlab::eng)

# matlab_add_mex(NAME engine_c EXECUTABLE SRC Cengine.c LINK_TO ${Matlab_LIBRARIES})

add_test(NAME Engine_C COMMAND engine_c)

endif(Matlab_engine_C)

# --- C++ calling Matlab engine

if(Matlab_engine_CXX)

add_executable(engine_cpp CppEngine.cpp)
if(APPLE)
  message(VERBOSE "macOS engine workaround to avoid header include failure with R2024b")
  target_compile_features(engine_cpp PRIVATE cxx_std_11)
endif()
target_link_libraries(engine_cpp PRIVATE Matlab::MatlabEngine Matlab::MatlabDataArray ${CMAKE_THREAD_LIBS_INIT})

# matlab_add_mex(NAME engine_cpp EXECUTABLE SRC CppEngine.cpp LINK_TO ${Matlab_LIBRARIES})

# add_custom_target(engine_cpp ALL
# COMMAND ${Matlab_MEX_COMPILER} -client engine ${CMAKE_CURRENT_SOURCE_DIR}/CppEngine.cpp
# BYPRODUCTS engine_cpp${CMAKE_EXECUTABLE_SUFFIX}
# )

add_test(NAME engine_cpp COMMAND engine_cpp)
set_property(TEST engine_cpp PROPERTY SKIP_REGULAR_EXPRESSION "libstdc;GLIBCXX")

endif(Matlab_engine_CXX)

# --- Fortran calling Matlab Engine

if(Matlab_engine_Fortran)
  add_executable(engine_fortran FortranEngine.F90)
  target_link_libraries(engine_fortran PRIVATE Matlab::eng)

  add_test(NAME Engine_Fortran COMMAND engine_fortran)
endif(Matlab_engine_Fortran)

# --- Engine test props

get_property(test_names DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY TESTS)
set_property(TEST ${test_names} PROPERTY RESOURCE_LOCK mengine)
# seems to intermittently crash if multiple engines running at once

matlab_libpath("${test_names}")
