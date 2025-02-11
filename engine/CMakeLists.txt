set_property(DIRECTORY PROPERTY LABELS "engine")

set(_method "wrap")

# --- C calling Matlab Engine

if(_method STREQUAL "cmake")

  add_executable(engine_c c.c)
  target_link_libraries(engine_c PRIVATE Matlab::eng)
  set(exe $<TARGET_FILE:engine_c>)

elseif(_method STREQUAL "find")

  matlab_add_mex(NAME engine_c EXECUTABLE SRC c.c LINK_TO ${Matlab_LIBRARIES})
  set(exe $<TARGET_FILE:engine_c>)

elseif(_method STREQUAL "wrap")

  set(src ${CMAKE_CURRENT_SOURCE_DIR}/c.c)
  # have to name exe distinctively from target or Ninja will get dependency cycle error
  set(exe ${CMAKE_CURRENT_BINARY_DIR}/engineC${CMAKE_EXECUTABLE_SUFFIX})

  add_custom_command(OUTPUT ${exe}
  COMMAND ${Matlab_MEX_COMPILER} -client engine ${src} -output ${exe}
  DEPENDS ${src}
  VERBATIM
  )

  add_custom_target(engine_c ALL DEPENDS ${exe})

endif()

add_test(NAME EngineC COMMAND ${exe})
matlab_libpath(EngineC)

# --- C++ calling Matlab engine

if(_method STREQUAL "cmake")

  add_executable(engine_cpp cpp.cpp)
  if(APPLE)
    message(VERBOSE "macOS engine workaround to avoid header include failure with R2024b")
    target_compile_features(engine_cpp PRIVATE cxx_std_11)
  endif()
  target_link_libraries(engine_cpp PRIVATE Matlab::MatlabEngine Matlab::MatlabDataArray ${CMAKE_THREAD_LIBS_INIT})
  set(exe $<TARGET_FILE:engine_cpp>)

elseif(_method STREQUAL "find")

  matlab_add_mex(NAME engine_cpp EXECUTABLE SRC cpp.cpp LINK_TO ${Matlab_LIBRARIES})
  set(exe $<TARGET_FILE:engine_cpp>)

elseif(_method STREQUAL "wrap")

  set(src ${CMAKE_CURRENT_SOURCE_DIR}/cpp.cpp)
  set(exe ${CMAKE_CURRENT_BINARY_DIR}/engineCpp${CMAKE_EXECUTABLE_SUFFIX})

  add_custom_command(
    OUTPUT ${exe}
    COMMAND ${Matlab_MEX_COMPILER} -client engine ${src} -output ${exe}
    DEPENDS ${src}
    VERBATIM
  )

# Create an ALIAS TARGET
add_custom_target(engine_cpp ALL DEPENDS ${exe})

endif()

add_test(NAME EngineCpp COMMAND ${exe})
set_property(TEST EngineCpp PROPERTY SKIP_REGULAR_EXPRESSION "libstdc;GLIBCXX")
matlab_libpath(EngineCpp)

# --- Fortran calling Matlab Engine

if(Matlab_engine_Fortran)
  add_executable(engine_fortran fortran.F90)
  target_link_libraries(engine_fortran PRIVATE Matlab::eng)

  add_test(NAME EngineFortran COMMAND engine_fortran)
  matlab_libpath(EngineFortran)
endif()

# --- Engine test props

get_property(test_names DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY TESTS)
set_property(TEST ${test_names} PROPERTY RESOURCE_LOCK mengine)
# seems to intermittently crash if multiple engines running at once
