!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! dmvm.f90 benchmark demo code
! G. Hager, 2019
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
module constants
    implicit none

    integer, parameter :: sp = kind(0.0e0)
    integer, parameter :: dp = kind(0.0d0)
end module constants

module timing
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
end module timing

module util
    use constants
contains
  subroutine str2int(str,int,stat)
    implicit none
    ! Arguments
    character(len=*),intent(in) :: str
    integer,intent(out)         :: int
    integer,intent(out)         :: stat

    read(str,*,iostat=stat)  int
  end subroutine str2int

end module util

module solver
    use constants
    use timing
    use likwid

    integer :: rows,columns

  contains
  function densemvm(A,X,Y,rep) result(seconds)
    implicit none
    double precision :: seconds
    double precision, allocatable, intent(in) :: A(:,:), X(:)
    double precision, allocatable, intent(inout) :: Y(:)
    integer :: rep
    
    integer :: c,r,iter
    double precision :: S,E

    S = getTimeStamp()

    call likwid_MarkerStartRegion("bench")
    do iter=1,rep
       !DEC$ nounroll_and_jam
       do c=1,columns
          do r=1,rows
             Y(r) = Y(r) + A(r,c) * X(c)
          enddo
       enddo
       if(Y(rows/2)<0.d0) print *,Y(rows/2)
    enddo
    call likwid_MarkerStopRegion("bench")

    E = getTimeStamp()

    seconds = E-S

  end function densemvm

    function densemvmtest(A,X,Y,rep) result(seconds)
    implicit none
    double precision :: seconds
    double precision, allocatable, intent(in) :: A(:,:), X(:)
    double precision, allocatable, intent(inout) :: Y(:)
    integer :: rep
    
    integer :: c,r,iter
    double precision :: S,E

    S = getTimeStamp()

    do iter=1,rep
       !DEC$ nounroll_and_jam
       do c=1,columns
          do r=1,rows
             Y(r) = Y(r) + A(r,c) * X(c)
          enddo
       enddo
       if(Y(rows/2)<0.d0) print *,Y(rows/2)
    enddo

    E = getTimeStamp()

    seconds = E-S

  end function densemvmtest

end module solver

program dmvm
  use timing
  use constants
  use solver
  use util
  use likwid
  
  implicit none

  double precision, dimension(:),allocatable :: X,Y
  double precision, dimension(:,:),allocatable :: A
! Intel-specific: 64-byte alignment of allocatables
!DEC$ ATTRIBUTES ALIGN: 32 :: A
!DEC$ ATTRIBUTES ALIGN: 32 :: Y
!DEC$ ATTRIBUTES ALIGN: 32 :: X
  double precision :: MFLOPS,times(0:1),factor,walltime
  integer :: i,j,iter
  integer :: argc,stat
  character(len=32) :: arg

  call likwid_MarkerInit
  call likwid_MarkerRegisterRegion("bench")
  
  argc = command_argument_count()

  if (argc > 1) then
     call get_command_argument(1, arg)
     call str2int(trim(arg), rows, stat)
     call get_command_argument(2, arg)
     call str2int(trim(arg), columns, stat)
  else
     print *,"Usage: dmvm  <rows> <columns>"
     stop
  end if

  allocate(X(1:columns),Y(1:rows),A(1:rows,1:columns))
  
  ! init
  do i=1,columns
     X(i) = 3.d0
     do j=1,rows
        if(i.eq.1) Y(j) = 2.d0 
        A(j,i)=dble(i)*j/dble(rows)
     enddo
  enddo

  ! warm up
  times(0) = densemvmtest(A,X,Y,1)

  times(0) = 0.d0
  times(1) = 0.d0
  iter=1
  
  do while(times(0) < 0.6d0)
     times(0) = densemvmtest(A,X,Y,iter)
     if(times(0) > 0.2d0) exit
     factor = 0.6d0/(times(0) - times(1))
     iter = iter * factor
     times(1) = times(0)
  enddo

  walltime = densemvm(A,X,Y,iter)
  
  MFLOPS = 2.d0*dble(iter)*rows*columns/1.0d6/walltime
  print 111,iter,rows,columns,MFLOPS
111 format(i8,i10,i8,f8.0)
  deallocate(A,X,Y)
  call likwid_MarkerClose
  
end program dmvm

