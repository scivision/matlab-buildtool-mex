#include "fintrf.h"

!     fengdemo.f
!
!     This is a simple program that illustrates how to call the MATLAB
!     Engine functions from a FORTRAN program.
!
! Copyright 1984-2018 The MathWorks, Inc.
!======================================================================


program main

use, intrinsic :: iso_fortran_env, only: real64

implicit none

mwPointer, external :: engOpen, engGetVariable, mxCreateDoubleMatrix, mxGetDoubles
mwPointer :: ep, T, D
mwSize, parameter :: M=1, N=10
real(real64) ::  dist(N)
integer, external :: engPutVariable, engEvalString, engClose
integer :: temp, status
mwSize :: i
real(real64), parameter :: time(N)=[ 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]

call diagnose()

ep = engOpen("")
if (ep == 0) error stop 'Cannot start MATLAB engine'

T = mxCreateDoubleMatrix(M, N, 0)

call mxCopyReal8ToPtr(time, mxGetDoubles(T), N)

!> Place the variable T into the MATLAB workspace
status = engPutVariable(ep, 'T', T)

if (status /= 0) error stop 'engPutVariable failed'

!     Evaluate a function of time, distance = (1/2)g.*t.^2
!     (g is the acceleration due to gravity)

if (engEvalString(ep, 'D = .5.*(-9.8).*T.^2;') /= 0) error stop 'engEvalString failed'

D = engGetVariable(ep, 'D')

call mxCopyPtrToReal8(mxGetDoubles(D), dist, N)

print *, 'MATLAB computed the following distances:'
print *, '  time(s)  distance(m)'
do i=1,size(time)
  print '(2G10.3)', time(i), dist(i)
enddo

call mxDestroyArray(T)
call mxDestroyArray(D)
status = engClose(ep)

if (status /= 0) error stop 'engClose failed'

contains

subroutine diagnose()

character(1000) :: buf
integer :: ierr, L

call get_environment_variable("LD_LIBRARY_PATH", buf, length=L, status=ierr)
if(ierr == 0 .and. L > 0) print *, "LD_LIBRARY_PATH: " // trim(buf)

call get_environment_variable("DYLD_LIBRARY_PATH", buf, length=L, status=ierr)
if(ierr == 0 .and. L > 0) print *, "DYLD_LIBRARY_PATH: " // trim(buf)

call get_environment_variable("PATH", buf, length=L, status=ierr)
if(ierr == 0 .and. L > 0) print *, "PATH: " // trim(buf)

end subroutine diagnose

end program
