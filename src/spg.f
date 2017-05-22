C     =================================================================
C     File: spg.f
C     =================================================================

C     =================================================================
C     Module: Spectral Projected Gradient Method
C     =================================================================

C     Last update of any of the component of this module:

C     December 20, 2007.

C     Users are encouraged to download periodically updated versions of
C     this code at the TANGO Project web page:
C
C     www.ime.usp.br/~egbirgin/tango/
C     ================================================================
C     Modified to solve FSV and CNOP
C     Hongli Wang and Huizhen Yu. 
C     Nov. 2013
C     ================================================================
C     *****************************************************************
C     *****************************************************************

      subroutine spg(n,x,epsopt,maxit,maxfc,iprint,f,gpsupn,iter,fcnt,
     +spginfo,inform)
      use module_para
      implicit none

C     SCALAR ARGUMENTS
      double precision gpsupn,epsopt,f
      integer fcnt,inform,iprint,iter,maxfc,maxit,n,spginfo

C     ARRAY ARGUMENTS
      double precision x(n)

C     Subroutine SPG implements the Spectral Projected Gradient Method 
C     (Version 2: "Feasible continuous projected path") to find a 
C     local minimizers of a given function with convex constraints, 
C     described in
C
C     E.G. Birgin, J.M. Martinez and M. Raydan, "Nonmonotone spectral
C     projected gradient methods for convex sets", SIAM Journal on
C     Optimization 10, pp. 1196-1211, 2000.
C
C     The user must supply the external subroutines evalf, evalg and 
C     proj to evaluate the objective function and its gradient and to 
C     project an arbitrary point onto the feasible region.
C
C     This version 20 DEC 2007 by E.G.Birgin, J.M.Martinez and M.Raydan.

C     Other parameters (i means input, o means output):
C
C     n       (i)   number of variables
C     x       (i/o) initial guess on input, solution on output
C     epsopt  (i)   tolerance for the convergence criterion
C     maxit   (i)   maximum number of iterations
C     maxfc   (i)   maximum number of functional evaluations
C     iprint  (i)   controls output level (0 = no print)
C     f       (o)   functional value at the solution
C     gpsupn  (o)   sup-norm of the projected gradient at the solution
C     iter    (o)   number of iterations
C     fcnt    (o)   number of functional evaluations
C     spginfo (o)   indicates the reason for stopping
C     inform  (o)   indicates an error in an user supplied subroutine

C     spginfo:
C
C     0: Small continuous-projected-gradient norm
C     1: Maximum number of iterations reached
C     2: Maximum number of functional evaluations reached
C
C     spginfo remains unset if inform is not equal to zero on output

C     inform:
C
C       0: ok
C     -90: error in the user supplied evalf subroutine
C     -91: error in the user supplied evalg subroutine
C     -92: error in the user supplied proj  subroutine

C     PARAMETERS
      integer m
      double precision lmax,lmin
!      parameter ( m    =     100 )
      parameter ( m    =       10)
!      parameter ( nmax =  238356 )
      parameter ( lmin = 1.0d-30 )
      parameter ( lmax = 1.0d+30 )

C     LOCAL SCALARS
      integer i,lsinfo
      double precision fbest,fnew,lambda,sts,sty

C     LOCAL ARRAYS
      double precision g(nmax),gnew(nmax),gp(nmax),s(nmax),y(nmax),
     +        d(nmax),xbest(nmax),xnew(nmax),lastfv(0:m-1),xout(nmax)

      character fnic*8
      integer   nltry_ls,nlambda_scheme
C     EXTERNAL SUBROUTINES
      external ls,sevalf,sevalg,sproj

C     INTRINSIC FUNCTIONS
      intrinsic abs,max,min,mod

C     ==================================================================
C     Initialization
C     ==================================================================

C     Print problem information

      if ( iprint .gt. 0 ) then
          write(* ,fmt=1000)
          write(10,fmt=1000)
          write(* ,fmt=1010) n
          write(10,fmt=1010) n
      end if

C     Set some initial values:

C     error tracker
      inform = 0

C whl try second linear search after first failed. 2 = .true.
      nltry_ls = 2
C whl lambda compuation scheme 1: spg default 2: trial one
      nlambda_scheme = 2 
C     for counting number of iterations as well as functional evaluations
      iter = 0
      fcnt = 0

C     for the non-monotone line search
      do i = 0,m - 1
          lastfv(i) = - 1.0d+99
      end do

C     Project initial guess

      print*, 'spg_sproj_sumxx= ',sum(x*x)
      call sproj(n,x,inform)
      if ( inform .ne. 0 ) return

C     Compute function and gradient at the initial point

      call sevalf(n,x,f,xout,inform)
      if ( inform .ne. 0 ) return

      fcnt = fcnt + 1
      print*,'spg_iter_fcnt_cost= ',iter,fcnt,f
      print*,'spg_iter_fcnt_sumxx=',iter,fcnt,sum(x*x)
      print*,'spg_iter_fcnt_rate= ',iter,fcnt,-f/sum(x*x)
      write(10,*)'spg_iter_fcnt_cost= ',iter,fcnt,f
      write(10,*)'spg_iter_fcnt_sumxx=',iter,fcnt,sum(x*x)
      write(10,*)'spg_iter_fcnt_rate= ',iter,fcnt,-f/sum(x*x)

      !save ic
c      write(fnic,'(A5,I3.3)')'ic1d.',iter
c      open(2001,file=fnic,FORM='UNFORMATTED')
c      write(2001)x
c      close(2001)
c      print*,fnic

c       write(fnic,'(A5,I3.3)')'ie1d.',iter
c      open(2001,file=fnic,FORM='UNFORMATTED')
c      write(2001)xout
c      close(2001)
c      print*,fnic


      call sevalg(n,x,g,inform)
      !save grad 
c      write(fnic,'(A5,I3.3)')'gd1d.',iter
c      open(2001,file=fnic,FORM='UNFORMATTED')
c      write(2001)g
c      close(2001)
c      print*,fnic

      if ( inform .ne. 0 ) return

C     Store functional value for the non-monotone line search

      lastfv(0) = f

C     Compute continuous-project-gradient and its sup-norm

      do i = 1,n
          gp(i) = x(i) - g(i)
      end do

      print*, 'spg_sproj_sumgpgp= ',sum(gp*gp)
      call sproj(n,gp,inform)
      if (inform .ne. 0) return

      gpsupn = 0.0d0
      do i = 1,n
          gp(i) = gp(i) - x(i)
          gpsupn = max( gpsupn, abs( gp(i) ) )
      end do

C     Initial steplength
      if ( gpsupn .ne. 0.0d0) then
          lambda =  min( lmax, max( lmin, 1.0d0 / gpsupn ) )
      else
          lambda = 0.0d0
      end if
      print*,'spg_init_lambda_gpsupn= ',lambda,gpsupn
      print*,'spg_iter_fcnt_lambda= ',iter,fcnt,lambda
C     Initiate best solution and functional value

      fbest = f

      do i = 1,n
          xbest(i) = x(i)
      end do

C     ==================================================================
C     Main loop
C     ==================================================================

 100  continue

C     Print iteration information

      if ( iprint .gt. 0 ) then
          if ( mod(iter,10) .eq. 0 ) then
              write(* ,fmt=1020)
              write(10,fmt=1020)
          end if
          write(* ,fmt=1030) iter,f,gpsupn
          write(10,fmt=1030) iter,f,gpsupn
      end if

      open(20,file='spg.out')
      write(20,fmt=1040) n,iter,fcnt,f,gpsupn
      close(20)

C     ==================================================================
C     Test stopping criteria
C     ==================================================================

C     Test whether the continuous-projected-gradient sup-norm
C     is small enough to declare convergence

      if ( gpsupn .le. epsopt ) then
          spginfo = 0

          if ( iprint .gt. 0 ) then
              write(*, 1100)
              write(10,1100)
          end if

          go to 200
      end if

C     Test whether the number of iterations is exhausted

      if (iter .ge. maxit) then
          spginfo = 1

          if ( iprint .gt. 0 ) then
              write(*, 1110)
              write(10,1110)
          end if

          go to 200
      end if

C     Test whether the number of functional evaluations

      if (fcnt .ge. maxfc) then
          spginfo = 2

          if ( iprint .gt. 0 ) then
              write(*, 1120)
              write(10,1120)
          end if

          go to 200
      end if

C     ==================================================================
C     Iteration
C     ==================================================================

      iter = iter + 1

C     Compute search direction

      do i = 1,n
          d(i) = x(i) - lambda * g(i)
      end do

      print*, 'spg_sproj_sumdd= ',sum(d*d)
      !save lambda*g 
c      write(fnic,'(A5,I3.3)')'lg1d.',iter
c      open(2001,file=fnic,FORM='UNFORMATTED')
c      write(2001) lambda * g
c      close(2001)
c      write(fnic,'(A5,I3.3)')'gd1d.',iter
c      open(2001,file=fnic,FORM='UNFORMATTED')
c      write(2001) g
c      close(2001)

      call sproj(n,d,inform)
      if (inform .ne. 0) return

      do i = 1,n
          d(i) = d(i) - x(i)
      end do

C     Perform safeguarded quadratic interpolation along the spectral 
C     continuous projected gradient

      call ls(n,x,f,g,d,m,lastfv,maxfc,fcnt,fnew,xnew,xout,
     +lsinfo,inform)

c      write(fnic,'(A5,I3.3)')'ic1d.',iter
c      open(2001,file=fnic,FORM='UNFORMATTED')
c      write(2001) xnew
c      close(2001)

c      write(fnic,'(A5,I3.3)')'ie1d.',iter
c      open(2001,file=fnic,FORM='UNFORMATTED')
c      write(2001) xout
c      close(2001)


      print*,'spg_ls_cost= ',iter,fcnt,fnew      
      if ( inform .eq. -10) then
      print*, '!!!!!!!!!!!WARNING!!SPG2!!!!!!!!!'
      print*, 'Maximum_Linear_Research_Achieved!'
         if (nltry_ls .eq. 2) then 
             nltry_ls = nltry_ls + 1
            inform = 0
         end if
      end if

      if ( inform .ne. 0 ) then
         return
      end if
      if ( lsinfo .eq. 2 ) then
          spginfo = 2

          if ( iprint .gt. 0 ) then
              write(*, 1120)
              write(10,1120)
          end if

          go to 200
      end if

C     Set new functional value and save it for the non-monotone line 
C     search

      f = fnew
      lastfv(mod(iter,m)) = f

C     Gradient at the new iterate

      call sevalg(n,xnew,gnew,inform)
      !save grad
c      write(fnic,'(A5,I3.3)')'gd1d.',iter
c      open(2001,file=fnic,FORM='UNFORMATTED')
c      write(2001)g
c      close(2001)
c      print*,fnic

      if ( inform .ne. 0 ) return

C     Compute s = xnew - x and y = gnew - g, <s,s>, <s,y>, the 
C     continuous-projected-gradient and its sup-norm

      sts = 0.0d0
      sty = 0.0d0
      do i = 1,n
          s(i)  = xnew(i) - x(i)
          y(i)  = gnew(i) - g(i)
          sts   = sts + s(i) ** 2
          sty   = sty + s(i) * y(i)
          x(i)  = xnew(i)
          g(i)  = gnew(i)
          gp(i) = x(i) - g(i)
      end do

      print*, 'spg_sproj_sumgpgp= ',sum(gp*gp)
      call sproj(n,gp,inform)
      if ( inform .ne. 0 ) return

      gpsupn = 0.0d0
      do i = 1,n
          gp(i) = gp(i) - x(i)
          gpsupn = max( gpsupn, abs( gp(i) ) )
      end do

C     Spectral steplength
      print*,'spg_sts_sty= ',sts,sty
      print*,'spg_sts/sty= ',sts/sty
      if (nlambda_scheme.eq.1) then
c     For cnop and fsv, sty may be lt 0.0 
        if ( sty .le. 0.0d0 ) then
           lambda = lmax
        else
           lambda = max( lmin, min( sts / sty, lmax ) )
        end if
      elseif(nlambda_scheme.eq.2) then
        if ( sty .ne. 0.0d0 ) then
           lambda = max( lmin, min( abs(sts / sty), lmax ) )
           ! min makes lambda <= lmax
           !if (lambda .gt. lmax)  lambda = lmax
        elseif ( sty .eq. 0.0d0 ) then
          lambda = lmax
        end if
      end if 
      print*,'spg_iter_fcnt_lambda= ',iter,fcnt,lambda
C     Best solution and functional value

      if ( f .lt. fbest ) then
      print*,'spg_iter_fcnt_cost= ',iter,fcnt,f
      print*,'spg_iter_fcnt_sumxx=',iter,fcnt,sum(x*x)
      print*,'spg_iter_fcnt_rate= ',iter,fcnt,-f/sum(x*x)
      write(10,*)'spg_iter_fcnt_cost= ',iter,fcnt,f
      write(10,*)'spg_iter_fcnt_sumxx=',iter,fcnt,sum(x*x)
      write(10,*)'spg_iter_fcnt_rate= ',iter,fcnt,-f/sum(x*x)

c      write(fnic,'(A5,I3.3)')'ic1d_best.',iter
c      open(2001,file=fnic,FORM='UNFORMATTED')
c      write(2001)x
c      close(2001)
c      print*,fnic

          fbest = f

          do i = 1,n
              xbest(i) = x(i)
          end do
      end if

C     ==================================================================
C     Iterate
C     ==================================================================

      go to 100

C     ==================================================================
C     End of main loop
C     ==================================================================

 200  continue

C     ==================================================================
C     Write statistics
C     ==================================================================

      if ( iprint .gt. 0 ) then
          write(* ,fmt=2000) iter,fcnt,f,gpsupn
          write(10,fmt=2000) iter,fcnt,f,gpsupn
      end if

C     ==================================================================
C     Finish returning the best point
C     ==================================================================

      f = fbest

      do i = 1,n
          x(i) = xbest(i)
      end do

C     ==================================================================
C     NON-EXECUTABLE STATEMENTS
C     ==================================================================

 1000 format(/,1X,78('='),
     +       /,1X,'This is the SPECTRAL PROJECTED GRADIENT (SPG) for ',
     +            'for convex-constrained',/,1X,'optimization. If you ',
     +            'use this code, please, cite:',/,
     +       /,1X,'E. G. Birgin, J. M. Martinez and M. Raydan, ',
     +            'Nonmonotone spectral projected',/,1X,'gradient ',
     +            'methods on convex sets, SIAM Journal on ',
     +            'Optimization 10, pp.',/,1X,'1196-1211, 2000, and',/,
     +       /,1X,'E. G. Birgin, J. M. Martinez and M. Raydan, ',
     +            'Algorithm 813: SPG - software',/,1X,'for ',
     +            'convex-constrained optimization, ACM Transactions ',
     +            'on Mathematical',/,1X,'Software 27, pp. 340-349, ',
     +            '2001.',/,1X,78('='))

 1010 format(/,1X,'Entry to SPG.',
     +       /,1X,'Number of variables: ',I7)

 1020 format(/,4X,'ITER',10X,'F',8X,'GPSUPN')

 1030 format(  1X,I7,1X,1P,D16.8,1X,1P,D7.1)
 1040 format(  1X,I7,1X,I7,1X,I7,1X,1P,D16.8,1X,1P,D7.1,1X,'(Abnormal ',
     +         'termination. Probably killed by CPU time limit.)')

 1100 format(/,1X,'Flag of SPG: Solution was found.')
 1110 format(/,1X,'Flag of SPG: Maximum of iterations reached.')
 1120 format(/,1X,'Flag of SPG: Maximum of functional evaluations ',
     +            'reached.')
 1130 format(/,1X,'Flag of SPG: Too small step in the line search.',
     +       /,1X,'Probably, an exaggerated small norm of the ',
     +            'continuous projected gradient',
     +       /,1X,'is being required for declaring convergence.')

 2000 format(/,1X,'Number of iterations               : ',9X,I7,
     +       /,1X,'Number of functional evaluations   : ',9X,I7,
     +       /,1X,'Objective function value           : ',1P,D16.8,
     +       /,1X,'Sup-norm of the projected gradient : ',9X,1P,D7.1)

      end

C     *****************************************************************
C     *****************************************************************

      subroutine ls(n,x,f,g,d,m,lastfv,maxfc,fcnt,fnew,xnew,xout,lsinfo,
     +inform)

      implicit none

C     SCALAR ARGUMENTS
      integer inform,lsinfo,maxfc,fcnt,m,n
      double precision f,fnew

C     ARRAY ARGUMENTS
      double precision d(n),g(n),lastfv(0:m-1),x(n),xnew(n),xout(n)

C     Nonmonotone line search with safeguarded quadratic interpolation
 
C     lsinfo:
C
C     0: Armijo-like criterion satisfied
C     2: Maximum number of functional evaluations reached

C     PARAMETERS
      double precision gamma
      parameter ( gamma     = 1.0d-04 )

C     LOCAL SCALARS
      integer i
      double precision alpha,atemp,fmax,gtd
C whl maximum number of ls
      integer nmax_ls,ntry_ls
C     EXTERNAL SUBROUTINES
      external sevalf

C     INTRINSIC FUNCTIONS
      intrinsic abs,max

C     Initiate

C whl 
      nmax_ls = 100
      ntry_ls = 0

      fmax = lastfv(0)
      do i = 1,m - 1
          fmax = max( fmax, lastfv(i) )
      end do

      gtd = 0.0d0
      do i = 1,n
         gtd = gtd + g(i) * d(i)
      end do

      alpha = 1.0d0

      do i = 1,n
          xnew(i) = x(i) + alpha * d(i)
      end do

      call sevalf(n,xnew,fnew,xout,inform)
      print*,'ls_linear_search1= ',fcnt,fnew,inform
      if ( inform .ne. 0 ) return

      fcnt = fcnt + 1
      ntry_ls = ntry_ls + 1

C     Main loop

 100  continue

C     Test stopping criteria
      print*,'fmax_df= ',fmax, gamma * alpha * gtd

      if ( fnew .le. fmax + gamma * alpha * gtd ) then
          lsinfo = 0
          return
      end if

      if (fcnt .ge. maxfc) then
          lsinfo = 2
          return
      end if 

C     Safeguarded quadratic interpolation

      if ( alpha .le. 0.1d0 ) then
          alpha = alpha / 2.0d0

      else
          atemp = ( - gtd * alpha ** 2 ) / 
     +            ( 2.0d0 * ( fnew - f - alpha * gtd ) )

          if ( atemp .lt. 0.1d0 .or. atemp .gt. 0.9d0 * alpha ) then
              atemp = alpha / 2.0d0
          end if

          alpha = atemp
      end if

C     New trial

      do i = 1,n
          xnew(i) = x(i) + alpha * d(i)
      end do

      call sevalf(n,xnew,fnew,xout,inform)
      print*,'ls_linear_search2= ',fcnt,fnew,inform
      ntry_ls = ntry_ls + 1

      if ( inform .ne. 0 ) return

      fcnt = fcnt + 1
C whl
      if (ntry_ls .gt. nmax_ls ) then 
      print*, '!!!!!!!!!!!WARNING!!!!!!!!!!!!!!!'
      print*, 'Maximum_Linear_Research_Achieved!'
      print*, 'Rescale_Initial_Guess_IC_to_0.1x!'
      do i = 1,n
          xnew(i) = 0.1*x(i) 
      end do

      do i = 0,m - 1
          lastfv(i) = - 1.0d+99
      end do

      inform = -10 
      return
      end if
C     Iterate

      go to 100

      end

C     *****************************************************************
C     *****************************************************************

      subroutine sevalf(n,x,f,xout,inform)

      implicit none

C     SCALAR ARGUMENTS
      integer inform,n
      double precision f

C     ARRAY ARGUMENTS
      double precision x(n),xout(n)

C     LOCAL SCALARS
      integer flag

C     EXTERNAL SUBROUTINES
      external evalf,reperr
      print*,'sevalf_sumxx= ',sum(x*x),flag
      call evalf(n,x,f,xout,flag)
      print*,'sevalf_f= ',f,flag

C     This is true if f if Inf, - Inf or NaN
      if ( .not. f .gt. - 1.0d+99 .or. .not. f .lt. 1.0d+99 ) then
          f = 1.0d+99
      end if

      if ( flag .ne. 0 ) then
          inform = - 90
          call reperr(inform)
          return
      end if

      end

C     *****************************************************************
C     *****************************************************************

      subroutine sevalg(n,x,g,inform)

      implicit none

C     SCALAR ARGUMENTS
      integer inform,n

C     ARRAY ARGUMENTS
      double precision g(n),x(n)

C     LOCAL SCALARS
      integer flag

C     EXTERNAL SUBROUTINES
      external evalg,reperr

      print*,'sevalg_sumxx= ',sum(x*x),flag
      call evalg(n,x,g,flag)
      print*,'sevalg_sumgg= ',sum(g*g),flag

      if ( flag .ne. 0 ) then
          inform = - 91
          call reperr(inform)
          return
      end if

      end

C     *****************************************************************
C     *****************************************************************

      subroutine sproj(n,x,inform)

      implicit none

C     SCALAR ARGUMENTS
      integer inform,n

C     ARRAY ARGUMENTS
      double precision x(n)

C     LOCAL SCALARS
      integer flag

C     EXTERNAL SUBROUTINES
      external proj,reperr

      call proj(n,x,flag)

      if ( flag .ne. 0 ) then
          inform = - 92
          call reperr(inform)
          return
      end if

      end

C     ******************************************************************
C     ******************************************************************

      subroutine reperr(inform)

      implicit none

C     SCALAR ARGUMENTS
      integer inform

      if ( inform .eq. -90 ) then
          write(* ,fmt=100) 'EVALF'
          write(10,fmt=100) 'EVALF'

      else if ( inform .eq. -91 ) then
          write(* ,fmt=100) 'EVALG'
          write(10,fmt=100) 'EVALG'

      else if ( inform .eq. -92 ) then
          write(* ,fmt=100) 'PROJ '
          write(10,fmt=100) 'PROJ '
      end if

C     NON-EXECUTABLE STATEMENTS

 100  format(/,1X,'*** There was an error in the user supplied ',
     +            'subroutine ',A10,' ***',/)

      end
