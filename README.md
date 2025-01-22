# Matlab build system

[![matlab](https://github.com/scivision/matlab-cmake-mex/actions/workflows/ci.yml/badge.svg)](https://github.com/scivision/matlab-cmake-mex/actions/workflows/ci.yml)

Examples of building Matlab MEX and Matlab Engine targets using
[Matlab supported compilers](https://www.mathworks.com/support/requirements/supported-compilers.html).
This project started with the purpose of demonstrating CMake with MEX and Matlab Engine.
Since R2023b, Matlab's own build system has become quite capable and is recommended over CMake for new projects.

One-time setup from Matlab:

```matlab
mex -setup c
mex -setup c++
mex -setup fortran
mex -setup -client engine c
mex -setup -client engine c++
mex -setup -client engine fortran
```

## Matlab MEX

Using Matlab's own build system to build and test MEX examples from the Matlab Command Window:

```matlab
buildtool mex

buildtool test:mex
```

## Matlab Engine

Matlab Engine is available from several languages including C, C++, Fortran, Python, ...
For compiled Matlab Engine programs, the appropriate "matlab" executable must be in environment variable PATH.

```matlab
buildtool engine

buildtool test:engine
```

The Matlab Engine examples might be shaky on certain systems and configurations.
Try running each example individually to see if any work.
List tasks by:

```matlab
buildtool -tasks all
```

Examples of running individual tests:

```matlab
buildtool test:engine:Cengine
buildtool test:engine:CppEngine
buildtool test:engine:FortranEngine
```

## CMake

CMake may be used to build and test MEX and Matlab Engine examples:

```sh
cmake -B build
cmake --build build

ctest --test-dir build -L mex -V

ctest --test-dir build -L engine -V
```

Currently, there is a
[known CMake bug](https://gitlab.kitware.com/cmake/cmake/-/issues/25068)
with `matlab_add_mex()` for Fortran that causes runtime failures of MEX binaries.
This happens on any operating system or Fortran compiler due to the issue with CMake `matlab_add_mex()`.

```
Invalid MEX-file 'matsq.mexa64': Gateway function is missing
```

## Linux: compiler and libstdc++ compatibility

Matlab has narrow windows of
[compiler versions](https://www.mathworks.com/support/requirements/supported-compilers-linux.html)
that work for each Matlab release.
Especially on Linux, this may require using a specific release of Matlab compatible such that Matlab libstdc++.so and system libstdc++.so are compatible.
This is because compiler-switching mechanisms like RHEL Developer Toolset still
[use system libstdc++](https://stackoverflow.com/a/69146673)
that lack newer GLIBCXX symbols.

* R2022a .. R2024b: Linux: GCC 10
* R2020b .. R2021b: Linux: GCC 8

A frequent issue on Linux systems is failure to link with libstdc++.so.6 correctly.
Depending on the particular Matlab version and system libstdc++, putting Matlab libstdc++ first in LD_LIBRARY_PATH may help:

```sh
LD_LIBRARY_PATH=<matlab_root>/sys/os/glnxa64/ cmake -Bbuild
```

It may be necessary to try different Matlab versions to find one
[Linux compatible](https://www.mathworks.com/support/requirements/matlab-linux.html)
with the particular Linux operating system vendor and version.

## Apple Silicon

macOS users with Apple Silicon CPU (M1, M2, ....) are required to use the native Apple Silicon Matlab.
Better performance for Matlab comes by using the native CPU version of Matlab matching the computer CPU.
However, while unsupported, if using Intel x86 Matlab on Apple Silicon CPU:

```sh
cmake -B build -DCMAKE_OSX_ARCHITECTURES=x86_64
```

## Compiler flags

Matlab MEX compiler appears to ignore "FFLAGS" environment variable conventionally used for passing Fortran compiler flags.
This becomes an issue when needing "-fallow-invalid-boz" for GCC > 10.
Newer Matlab versions pass this flag for every GFortran MEX.

## Reference

* [C Engine](https://www.mathworks.com/help/matlab/calling-matlab-engine-from-c-programs-1.html)
* [C++ Engine](https://www.mathworks.com/help/matlab/calling-matlab-engine-from-cpp-programs.html)
* [Fortran engine](https://www.mathworks.com/help/matlab/calling-matlab-engine-from-fortran-programs.html)

---

[GNU Octave from CMake](https://github.com/scivision/octave-cmake-mex)
