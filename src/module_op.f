C     =================================================================
C     File: module_op.f
C     =================================================================

C     =================================================================
C     Module: Spectral Projected Gradient Method. Problem definition.
C     =================================================================

C     Last update of any of the component of this module:

C     March 14, 2008.

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

      subroutine inip(ntdim,x)
      use module_para 
c      include 'da_unifva.inc'      
       
C     SCALAR ARGUMENTS
      integer ntdim
      real t,pi
C     ARRAY ARGUMENTS
      double precision x(ntdim),x0(ntdim),x1(ntdim),summ,ss

C     PARAMETERS
c      integer nmax
c      parameter ( nmax = 238356 )

C     LOCAL SCALARS
      integer i, m, n

C     Number of variables
      ntdim = nmax
   
      open (1000, form='unformatted')
       m = 1
       do i = 1, nVars
         n = nLon(i) * nLat(i) * nLev(i) * nTim(i) + m - 1
         read(1000) x(m:n)
         m = n + 1
       end do
       close(1000)

  
       summ = 0.0   
       do i=1 ,ntdim
         summ = summ + x(i)*x(i)
       end do
c       print*,summ
       do i =1 ,ntdim
         x(i) = x(i)/(sqrt(summ))
       end do
    
      end

C     *****************************************************************
C     *****************************************************************

      subroutine evalf(ntdim,x,f,xout,flag)
      use module_para

C     SCALAR ARGUMENTS
      double precision f
      integer m,n,i,flag,ntdim

C     ARRAY ARGUMENTS
      double precision x(ntdim),xout(ntdim)

      flag = 0

      open (1001, form='unformatted')
       m = 1
       do i = 1, nVars
         n = nLon(i) * nLat(i) * nLev(i) * nTim(i) + m - 1
         Write(1001) x(m:n)
!         Write(*,*) m,n
!         Write(*,fmt='(a,f12.9)') trim(vNam(i))//"(1,1,1,2) = ",x(m+1)
         m = n + 1
       end do
       close(1001)

        call system ( "./run_opb_f.csh" )
       ! wait until fort.1002 is updated

!       Write(*,*) "Read from 1002"
       open (1002, form='unformatted')
       m = 1
       do i = 1, nVars
         n = nLon(i) * nLat(i) * nLev(i) * nTim(i) + m - 1
         read(1002) xout(m:n)
!         Write(*,fmt='(a,f12.9)')trim(vNam(i))//"(1,1,1,2) =
!         ",xout(m+1)
         m = n + 1
       end do
       f=-sum(xout*xout)
       print*,'function = ',-f
!       xin=xout
       close(1002)

      end

C     *****************************************************************
C     *****************************************************************

      subroutine evalg(ntdim,x,g,flag)

      use module_para
C     SCALAR ARGUMENTS
      integer m,n,i,flag,ntdim

C     ARRAY ARGUMENTS
      double precision g(ntdim),x(ntdim),xout(ntdim)

      flag = 0

      open (1001, form='unformatted')
       m = 1
       do i = 1, nVars
         n = nLon(i) * nLat(i) * nLev(i) * nTim(i) + m - 1
         Write(1001) x(m:n)
!         Write(*,*) m,n
!         Write(*,fmt='(a,f12.9)') trim(vNam(i))//"(1,1,1,2) = ",x(m+1)
         m = n + 1
       end do
       close(1001)

        call system ( "./run_opb.csh" )
       ! wait until fort.1002 is updated

!       Write(*,*) "Read from 1002"
       open (1002, form='unformatted')
       m = 1
       do i = 1, nVars
         n = nLon(i) * nLat(i) * nLev(i) * nTim(i) + m - 1
         read(1002) xout(m:n)
!         Write(*,fmt='(a,f12.9)')trim(vNam(i))//"(1,1,1,2) =
!         ",xout(m+1)
         m = n + 1
        end do
        g=-2*xout
!        xin=xout
       close(1002)
      end

C     *****************************************************************
C     *****************************************************************
      subroutine proj(n,x,flag)
       use module_para

      implicit double precision (a-h,o-z)
C     SCALAR ARGUMENTS
      dimension x(n)
      common /blocka/ normp
      common /blockb/  deltm
      integer flag

c      delta = 60
      flag = 0
         sum = 0.0d0
         do i = 1, n
            sum = sum + x(i) * x(i)
         enddo
         sqrtsum = sqrt(sum)
         if (sqrtsum.le.delta)then
           print*,'proj sqrtsum<= ',sqrtsum
           return
         else
         c = delta / sqrtsum
         do i = 1, n
            x(i) = c * x(i)
         enddo
           print*,'proj sqrtsum>  ',sqrtsum,c
         return
         endif

       end


