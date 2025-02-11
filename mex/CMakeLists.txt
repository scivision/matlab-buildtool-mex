# https://www.mathworks.com/help/matlab/matlab_external/table-of-mex-file-source-code-files.html

set_property(DIRECTORY PROPERTY LABELS "mex")


set(_method wrap)

# --- C Mex

find_file(matmul_src
NAMES matrixMultiply.c
NO_DEFAULT_PATH
PATHS ${Matlab_ROOT_DIR}/extern/examples/refbook
)

if(matmul_src AND Matlab_MEX_BLAS)

if(_method STREQUAL "wrap")

  add_custom_command(OUTPUT matrixMultiply.${Matlab_MEX_SUFFIX}
  COMMAND ${Matlab_MEX_COMPILER} ${matmul_src} ${CMAKE_LIBRARY_PATH_FLAG}${Matlab_EXTERN_LIBRARY_DIR} ${Matlab_MEX_BLAS} -output matrixMultiply
  VERBATIM
  )

  add_custom_target(matrixMultiply ALL DEPENDS matrixMultiply.${Matlab_MEX_SUFFIX})

elseif(_method STREQUAL "find")
  matlab_add_mex(NAME matrixMultiply SHARED SRC ${matmul_src} LINK_TO ${Matlab_MEX_BLAS})
endif()

endif()

add_test(NAME C_MEX_BLAS
COMMAND ${Matlab_MAIN_PROGRAM} -sd ${PROJECT_SOURCE_DIR} -batch "buildtool test:mex:blas"
)
set_property(TEST C_MEX_BLAS PROPERTY DISABLED $<OR:$<NOT:$<TARGET_EXISTS:matrixMultiply>>,$<VERSION_LESS:${Matlab_VERSION},24.2>>)

# --- C++ Mex

find_file(array_src
NAMES arrayProduct.cpp
NO_DEFAULT_PATH
PATHS ${Matlab_ROOT_DIR}/extern/examples/cpp_mex
)

if(array_src)

if(_method STREQUAL "wrap")

  add_custom_command(OUTPUT arrayProduct.${Matlab_MEX_SUFFIX}
  COMMAND ${Matlab_MEX_COMPILER} ${array_src} -output arrayProduct
  VERBATIM
  )

  add_custom_target(arrayProduct ALL DEPENDS arrayProduct.${Matlab_MEX_SUFFIX})

elseif(_method STREQUAL "find")

matlab_add_mex(NAME arrayProduct SHARED SRC ${array_src})
if(APPLE)
  message(VERBOSE "macOS MEX workaround to avoid header include failure with R2024b")
  target_compile_features(arrayProduct PRIVATE cxx_std_11)
endif()

endif()

endif()

add_test(NAME CppMex
COMMAND ${Matlab_MAIN_PROGRAM} -sd ${PROJECT_SOURCE_DIR} -batch "buildtool test:mex:array"
)

set_property(TEST CppMex PROPERTY DISABLED $<OR:$<NOT:$<TARGET_EXISTS:arrayProduct>>,$<VERSION_LESS:${Matlab_VERSION},24.2>>)


# --- Fortran Mex called from Matlab

find_file(matsq_src
NAMES matsq.F
NO_DEFAULT_PATH
PATHS ${Matlab_ROOT_DIR}/extern/examples/refbook
)

if(matsq_src AND Matlab_mex_Fortran)

if(_method STREQUAL "wrap")

  add_custom_command(OUTPUT matsq.${Matlab_MEX_SUFFIX}
  COMMAND ${Matlab_MEX_COMPILER} ${matsq_src} -output matsq
  VERBATIM
  )

  add_custom_target(matsq ALL DEPENDS matsq.${Matlab_MEX_SUFFIX})

elseif(_method STREQUAL "find")
  matlab_add_mex(NAME matsq SHARED SRC ${matsq_src})
endif()

endif()

add_test(NAME FortranMex
COMMAND ${Matlab_MAIN_PROGRAM} -sd ${PROJECT_SOURCE_DIR} -batch "buildtool test:mex:fortran"
)
set_property(TEST FortranMex PROPERTY DISABLED $<OR:$<NOT:$<TARGET_EXISTS:matsq>>,$<VERSION_LESS:${Matlab_VERSION},24.2>>)


# --- properties
get_property(test_names DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY TESTS)

matlab_libpath("${test_names}")

set_property(TEST ${test_names} PROPERTY SKIP_RETURN_CODE 77)
