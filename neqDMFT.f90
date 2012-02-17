!###################################################################
!PURPOSE  : Solve conduction band electrons driven 
! by electric field interacting with a resevoir of free 
! electrons at temperature T
!AUTHORS  : Adriano Amaricci && Cedric Weber
!###################################################################
program neqDMFT
  USE VARS_GLOBAL                 !global variables, calls to 3rd library 
  USE ELECTRIC_FIELD              !contains electric field init && routines
  USE BATH                        !contains bath inizialization
  USE FUNX_NEQ                    !contains all the neqDMFT routines
  USE KADANOFBAYM                 !solves KB equations numerically to get k-sum
  implicit none

  logical :: converged
  complex(8),dimension(:,:),allocatable :: G0less_old,G0gtr_old

  call read_input_init("inputFILE.in",printf=.true.)
  include "grid_setup.f90"
  include "build_square_lattice.f90"

  !SET THE ELECTRIC FIELD:use constant field by default
  Ek = set_efield_vector(Ex,Ey)
  call print_Afield_form(t(0:nstep))

  !STARTS THE REAL WORK:
  call global_memory_allocation !allocate functions in the memory
  call get_bath()               !get the dissipative bath functions
  call guess_g0_sigma           !guess/read the first Weiss field/Sigma:

  allocate(G0less_old(0:nstep,0:nstep),G0gtr_old(0:nstep,0:nstep))
  iloop=0;converged=.false.
  do while (.not.converged);iloop=iloop+1
     call start_loop(iloop,nloop,"DMFT-loop",unit=6)
     G0less_old=G0less ; G0gtr_old =G0gtr
     call get_gloc_kadanoff_baym  !-|
     call update_weiss_field      !-|SELF-CONSISTENCY
     G0less = weight*G0less + (1.d0-weight)*G0less_old
     G0gtr = weight*G0gtr + (1.d0-weight)*G0gtr_old
     !
     call get_sigma               !-|IMPURITY SOLVER
     !
     call print_observables
     converged = convergence_check()
     call end_loop()
  enddo
  !call alloc_memory('d')
  print*,"BRAVO!"
end PROGRAM neqDMFT
