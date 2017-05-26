load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
       ;
       ; Hongli Wang and Huizhen Yu and Jianyu Liu NCAR/MMM 2013/10
       ;
begin
;;; need to change ;;;
;;define the boundry 
 boun = 2
 verti = 0 
;;; end of modified ;;;

;  t_scale=0.
;  mu_scale=0.
  q_scale=0.
;  t_scale=9.8/3.
;  mu_scale=1./300.
;    t_scale  =sqrt(1005.7/270)
    mu_scale =sqrt(287.04*270)/100000.

; adding the wrinput_d01 and reading mub
  wrfinput = addfile("wrfinput_d01.nc","r")
   mub=wrfinput->$"MUB"$
;adding the wrinput_d01 and reading mub


; making the delta of eta, and get the average of eta
  if ( .not. isvar("vEta") ) then
   vEta1=wrfinput->$"ZNW"$
   size = dimsizes(vEta1)
   vEta = reshape(vEta1,(/size(1)/))
;  print("vEta " + vEta)
   end if
  nEta = dimsizes(vEta) - 1
  ;print(nEta)
  t_scale  =sqrt(1005.7/270)*vEta^0.286

  if ( .not. isvar("vEta_delta") ) then
     vEta_delta = vEta
  end if


  do i = 0, nEta-1
     vEta_delta(i) = vEta(i)-vEta(i+1)
  end do
  tot_eta_delta=sum(vEta_delta(0:nEta-1))
; making the delta of eta, and get the average of eta

  if ( .not. isvar("vNam") ) then
    vNam=(/"A_U", "A_V", "A_T", "A_MU", "A_QVAPOR"/)
  end if

  if ( .not. isvar("ifil")) then
    ifil="gradient_wrfplus_d01"
  end if

  if ( .not. isvar("ofil")) then
    ofil="fort.1002"
  end if

  if ( .not. isfilepresent(ifil)) then
    print("File not found : " + ifil )
    status_exit(-1) 
  end if

  if ( isfilepresent(ofil)) then
    print("Warning : file "+ ofil + "exists,  will be overwritten")
    system ("/bin/rm " + ofil)
  end if

  print("Input  file : " + ifil )
  print("Output file : " + ofil )

  suffix = str_get_cols(ifil, -3, -1)
  if ( suffix .ne. ".nc" ) then
    suffix = ".nc"
  else
    suffix = ""
  end if

  f = addfile(ifil+suffix,"r")
  if ( ismissing(f) ) then
    print("Failed open file : " + ifil)
    status_exit(-1)
  end if

  nVars = dimsizes(vNam) - 1
  skipped = 0

  do i=0, nVars 

    print("Processing " + vNam(i))
    if ( .not. isfilevar(f, vNam(i)) ) then
      print("Warning : " + vNam(i) + " Not available in file " + ofil + ", skipped" )
      skipped = skipped + 1
      continue
    end if


   vc = f->$vNam(i)$
   vb = f->$vNam(i)$
   ;printVarSummary(vc)
   ;printVarSummary(vb)
   vc = 0.0 

   dsizes = dimsizes(vb)
   print(dsizes)
    if ( vNam(i) .eq. "A_U" ) then
      mub_u = new((/dsizes(2),dsizes(3)/),"double")
      mub_u(:,0:dsizes(3)-2) = mub(0,:,:)
      mub_u(:,dsizes(3)-1) = 2* mub_u(:,dsizes(3)-2) -  mub_u(:,dsizes(3)-3)
      do kk = verti, nEta-1
       do j = boun, dsizes(2)-boun
          do ii = boun, dsizes(3)-boun
             vc(0,kk,j,ii) = vb(0,kk,j,ii) ; /  mub_u(j,ii) / vEta_delta(kk)
          end do
       end do
      end do
    end if

    if ( vNam(i) .eq. "A_V" ) then
      mub_v = new((/dsizes(2),dsizes(3)/),"double")
      mub_v(0:dsizes(2)-2,:) = mub(0,:,:)
      mub_v(dsizes(2)-1,:) = 2* mub_v(dsizes(2)-2,:) -  mub_v(dsizes(2)-3,:)
      do kk = verti, nEta-1
       do j = boun, dsizes(2)-boun
          do ii = boun, dsizes(3)-boun
             vc(0,kk,j,ii) = vb(0,kk,j,ii) ; /  mub_v(j,ii) / vEta_delta(kk)
          end do
       end do
      end do
    end if


    if ( vNam(i) .eq. "A_T" ) then
;      if ( t_scale .eq.  0.0 ) then
;           vc=vb * t_scale
;        else
      do kk = verti, nEta-1
       do j = boun, dsizes(2)-boun
          do ii = boun, dsizes(3)-boun
           vc(0,kk,j,ii) = vb(0,kk,j,ii)  / (t_scale(kk)) ;/ mub(0,j,ii) / vEta_delta(kk)
          end do
       end do
      end do
;     end if
    end if

    if ( vNam(i) .eq. "A_MU" ) then
      if ( mu_scale .eq.  0.0 ) then
           vc=vb * mu_scale
       else

       do j = boun, dsizes(1)-boun
          do ii = boun, dsizes(2)-boun
             vc(0,j,ii)=vb(0,j,ii)/(mu_scale) ;/  mub(0,j,ii) / tot_eta_delta
          end do
       end do
      end if
    end if

    if ( vNam(i) .eq. "A_QVAPOR" ) then
       if ( q_scale .eq.  0.0 ) then
           vc=vb * q_scale
       else
         do kk = verti, nEta-1
            do j = boun, dsizes(2)-boun
               do ii = boun, dsizes(3)-boun
                  vc(0,kk,j,ii) = vb(0,kk,j,ii)  / (q_scale) ;/mub(0,j,ii) / vEta_delta(kk)
               end do
            end do
         end do
       end if
    end if

 
   fbinrecwrite (ofil, -1, vc)

   if ( vNam(i) .ne. "A_MU" ) then
;   sample = doubletofloat(f->$vNam(i)$(0,0,0,1))
      sample = doubletofloat(vc(0,5,20,20))
      print("(0,5,20,20) = " + flt2string(sample))
   end if
   if ( vNam(i) .eq. "A_MU" ) then
;   sample = doubletofloat(f->$vNam(i)$(0,0,1))
      sample = doubletofloat(vc(0,20,20))
      print("(0,20,20) = " + flt2string(sample))
   end if
   delete(vc)
   delete(vb) 
   delete(dsizes)
  end do

  delete(mub)
  delete(mub_u)
  delete(mub_v)

  if ( skipped .gt. 0 ) then
    print("Failed to process all variables")
  else
    print("Completed successfully")
  end if

end
