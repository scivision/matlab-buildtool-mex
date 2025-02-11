# https://www.mathworks.com/support/requirements/supported-compilers.html
include(CheckSourceCompiles)

# set(CMAKE_EXECUTE_PROCESS_COMMAND_ECHO STDOUT)

# let default C++ version -- Matlab sets it recent enough.

add_compile_definitions($<$<AND:$<BOOL:${MSVC}>,$<COMPILE_LANGUAGE:C,CXX>>:_CRT_SECURE_NO_WARNINGS>)

if(CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
  if(CMAKE_Fortran_COMPILER_VERSION VERSION_GREATER_EQUAL 10)
    add_compile_options($<$<COMPILE_LANGUAGE:Fortran>:-fallow-invalid-boz>)
  endif()
endif()

# matlab_add_mex etc. may redefine macros, but -Wno-macro-redefined is only available for Clang.
# GCC gives the warning but doesn't have a way to disable the warning.


find_package(Threads)

function(find_mex_libs)
# MEX BLAS may need to be linked for targets using BLAS
set(_suffix)
if(MSVC)
  set(CMAKE_FIND_LIBRARY_PREFIXES "lib")
  set(_suffix microsoft)
elseif(MINGW)
  set(_suffix mingw64)
endif()

find_library(Matlab_MEX_BLAS
NAMES mwblas
NO_DEFAULT_PATH
PATHS ${Matlab_EXTERN_LIBRARY_DIR} ${Matlab_BINARIES_DIR}
PATH_SUFFIXES ${_suffix}
)
message(STATUS "Matlab BLAS library: ${Matlab_MEX_BLAS}")
endfunction()

find_mex_libs()

matlab_get_mex_suffix(${Matlab_ROOT_DIR} Matlab_MEX_SUFFIX)
message(STATUS "MEX suffix: ${Matlab_MEX_SUFFIX}")

function(matlab_libpath test_names)

if(APPLE)
  set_property(TEST ${test_names} PROPERTY
  ENVIRONMENT_MODIFICATION "DYLD_LIBRARY_PATH=path_list_prepend:${Matlab_EXTERN_BINARIES_DIR};PATH=path_list_prepend:${Matlab_ROOT_DIR}/bin"
  )
elseif(WIN32)
  set_property(TEST ${test_names} PROPERTY
  ENVIRONMENT_MODIFICATION "PATH=path_list_prepend:${Matlab_BINARIES_DIR};PATH=path_list_prepend:${Matlab_EXTERN_BINARIES_DIR};PATH=path_list_prepend:${Matlab_ROOT_DIR}/bin"
  )
else()
  set_property(TEST ${test_names} PROPERTY
  ENVIRONMENT_MODIFICATION "LD_LIBRARY_PATH=path_list_prepend:${Matlab_BINARIES_DIR}:${Matlab_EXTERN_BINARIES_DIR}:${Matlab_ROOT_DIR}/sys/os/glnxa64;PATH=path_list_prepend:${Matlab_ROOT_DIR}/bin"
  )
endif()

endfunction(matlab_libpath)


function(check_mex lang src_file)

if(DEFINED Matlab_mex_${lang})
  return()
endif()

set(cmd ${Matlab_MEX_COMPILER} -outdir ${PROJECT_BINARY_DIR}/cmake ${src_file})

message(CHECK_START "Check Matlab MEX ${lang}")

execute_process(
COMMAND ${cmd}
TIMEOUT 60
RESULT_VARIABLE ret
ERROR_VARIABLE err
OUTPUT_VARIABLE out
)

if(ret EQUAL 0)
  message(CHECK_PASS "Success")
  set(Matlab_mex_${lang} true CACHE BOOL "Matlab Mex ${lang} OK")
else()
  message(CHECK_FAIL "Failed: ${cmd}
  ${ret}
  ${out}
  ${err}")
  message(CONFIGURE_LOG "Check Matlab MEX ${lang} failed: ${cmd}
  ${ret}
  ${out}
  ${err}")
  set(Matlab_mex_${lang} false CACHE BOOL "Matlab Mex ${lang} not working")
endif()

endfunction(check_mex)


set(CMAKE_REQUIRED_LIBRARIES ${Matlab_LIBRARIES} ${CMAKE_THREAD_LIBS_INIT})
set(CMAKE_REQUIRED_INCLUDES ${Matlab_INCLUDE_DIRS})

# --- check C Engine
# file(READ ${CMAKE_CURRENT_LIST_DIR}/engine.c _src)
# check_source_compiles(C "${_src}" Matlab_engine_C)

# --- check C Mex
# find_file(times_src
# NAMES timestwo.c
# NO_DEFAULT_PATH
# PATHS ${Matlab_ROOT_DIR}/extern/examples/refbook
# )
# if(times_src)
#   check_mex("C" ${times_src})
# endif()

# --- check C++ Engine

# file(READ ${CMAKE_CURRENT_LIST_DIR}/engine.cpp _src)
# check_source_compiles(CXX "${_src}" Matlab_engine_CXX)

# --- check C++ Mex
# find_file(array_src
# NAMES arrayProduct.cpp
# NO_DEFAULT_PATH
# PATHS ${Matlab_ROOT_DIR}/extern/examples/cpp_mex
# )
# if(array_src)
#   check_mex("CXX" ${array_src})
# endif()

# --- check Fortran engine
if(NOT fortran)
  return()
endif()

file(READ ${CMAKE_CURRENT_LIST_DIR}/engine.f90 _src)
check_source_compiles(Fortran "${_src}" Matlab_engine_Fortran)

find_file(matsq_src
NAMES matsq.F
NO_DEFAULT_PATH
PATHS ${Matlab_ROOT_DIR}/extern/examples/refbook
)

if(matsq_src)
  check_mex("Fortran" ${matsq_src})
endif()
