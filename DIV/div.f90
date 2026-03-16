!=======================================================================================
!
!     Authors:   Jan Eitzinger (je), jan.eitzinger@fau.de
!     Copyright (c) 2020 RRZE, University Erlangen-Nuremberg
!
!     Permission is hereby granted, free of charge, to any person obtaining a copy
!     of this software and associated documentation files (the "Software"), to deal
!     in the Software without restriction, including without limitation the rights
!     to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
!     copies of the Software, and to permit persons to whom the Software is
!     furnished to do so, subject to the following conditions:
!
!     The above copyright notice and this permission notice shall be included in all
!     copies or substantial portions of the Software.
!
!     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
!     IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
!     FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
!     AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
!     LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
!     OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
!     SOFTWARE.#include <stdlib.h>
!
!=======================================================================================

module timer
    use iso_fortran_env, only: int32, int64, real64
    implicit none
    public :: getTimeStamp
contains
    function getTimeStamp() result(ts)
        implicit none

        integer(int64) :: counter, count_step
        real(real64) :: ts

        call system_clock(counter, count_step)
        ts = counter / real(count_step,real64)
    end function getTimeStamp
end module timer

program div
    use iso_fortran_env, only:  real64
    use timer
    implicit none
    real(real64) :: S, E
    integer :: i,k
    integer, parameter :: N = 2000000000
    double precision :: delta_x,x,sum

    delta_x = 1.d0/N

    do k=0,1
      sum = 0.d0
      S = getTimeStamp()

      !DIR$ UNROLL= 32
      do i=1,N
        x = (i-0.5d0)*delta_x
        sum = sum + (4.d0 / (1.d0 + x * x))
      enddo

      E = getTimeStamp()
    enddo

    write(*,*) 'Pi=', sum * delta_x,' in ', E-S,'s'

end program div
