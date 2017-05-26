load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
       ;
       ; Hongli Wang and Huizhen Yu and Jianyu Liu NCAR/MMM 2013/10
       ;
begin
 veri = asciiread("../verification",(/6/),"integer")
;print(veri)
 ist = veri(0)
;print("ist = " + ist)
 ied = veri(1)
 jst = veri(2)
 jed = veri(3)
 kst = veri(4)
 ked = veri(5)
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
; adding the wrinput_d01 and reading mub

; making the delta of eta, and get the average of eta
  if ( .not. isvar("vEta") ) then
   vEta1=wrfinput->$"ZNW"$
   size = dimsizes(vEta1)
   vEta = reshape(vEta1,(/size(1)/))
;  print("vEta " + vEta)
  end if
  t_scale  =sqrt(1005.7/270)*vEta^0.286

  nEta = dimsizes(vEta) - 1


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
    ifil="auxhist_d01"
  end if

  if ( .not. isvar("ofil")) then
    ofil="gradient_wrfplus_d01"
  end if

  if ( .not. isfilepresent(ifil)) then
    print("File not found : " + ifil )
    status_exit(-1)
  end if

  fils = (/ifil, ofil/)

  if ( .not. all(isfilepresent(fils)) ) then
    print("File not found : " + ifil + "/" + ofil)
    status_exit(-1) 
  end if

  print("Input  file : " + ifil )
  print("Output file : " + ofil )

  suffix = str_get_cols(ifil, -3, -1)
  if ( suffix .ne. ".nc" ) then
    suffix = ".nc"
  else
    suffix = ""
  end if

  f_auxhist = addfile(ifil+suffix,"r")
  if ( ismissing(f_auxhist) ) then
    print("Failed open file : " + ifil)
    status_exit(-1)
  end if

  suffix = str_get_cols(ofil, -3, -1)
  if ( suffix .ne. ".nc" ) then
    suffix = ".nc"
  else
    suffix = ""
  end if

  f_final_sens = addfile(ofil+suffix,"rw")
  if ( ismissing(f_final_sens) ) then
    print("Failed open file : " + ofil)
    status_exit(-1)
  end if

  nVars = dimsizes(vNam) - 1
  skipped = 0

  do i=0, nVars 

    A_VAR=vNam(i)
    G_VAR = "G"+str_get_cols(A_VAR, 1, -1)

    print("Processing " + A_VAR)

    if ( .not. isfilevar(f_auxhist, G_VAR) ) then
      print("Warning : " + G_VAR + " Not available in file " + ifil + ", skipped")
      skipped = skipped + 1
      continue
    end if

    if ( .not. isfilevar(f_final_sens, A_VAR ))  then
      print("Warning : " + A_VAR + " Not available in file " + ofil + ", skipped")
      ;skipped = skipped + 1
      ;continue
    end if
    vc = f_auxhist->$G_VAR$
    vb = f_auxhist->$G_VAR$

    vc = 0.

    dsizes = dimsizes(vb)
    if ( G_VAR .eq. "G_T" ) then
    do k = kst-1, ked-1
       do j = jst-1, jed-1
          do ii = ist-1, ied-1
             vc(0,k,j,ii) = vb(0,k,j,ii)*(t_scale(k)) ;* mub(0,j,ii) * vEta_delta(k)
             ;vc(0,k,j,ii) = 0.1
          end do
       end do
    end do
    end if
    if ( G_VAR .eq. "G_U" ) then
       mub_u = new((/dsizes(2),dsizes(3)/),"double")
       mub_u(:,0:dsizes(3)-2) = mub(0,:,:)
       mub_u(:,dsizes(3)-1) = 2* mub_u(:,dsizes(3)-2) -  mub_u(:,dsizes(3)-3)
    do k = kst-1, ked-1
       do j = jst-1, jed-1
          do ii = ist-1, ied-1
             vc(0,k,j,ii) = vb(0,k,j,ii) ;* mub_u(j,ii) * vEta_delta(k)
          end do
       end do
    end do
    end if
     if ( G_VAR .eq. "G_V" ) then
      mub_v = new((/dsizes(2),dsizes(3)/),"double")
      mub_v(0:dsizes(2)-2,:) = mub(0,:,:)
      mub_v(dsizes(2)-1,:) = 2* mub_v(dsizes(2)-2,:) -  mub_v(dsizes(2)-3,:)
    do k = kst-1, ked-1
       do j = jst-1, jed-1
          do ii = ist-1, ied-1
             vc(0,k,j,ii) = vb(0,k,j,ii) ;* mub_v(j,ii) * vEta_delta(k)

          end do
       end do
    end do
    end if
    if ( G_VAR .eq. "G_QVAPOR" ) then
       if( q_scale .eq. 0.0 ) then
             vc = vb * q_scale
       else
	    do k = kst-1, ked-1
	       do j = jst-1, jed-1
	          do ii = ist-1, ied-1
	             vc(0,k,j,ii) = vb(0,k,j,ii)* (q_scale) ;* mub(0,j,ii) * vEta_delta(k)

	          end do
	       end do
	    end do
       end if
    end if
 
    if ( G_VAR .eq. "G_MU" ) then
       do j = jst-1, jed-1
          do ii = ist-1, ied-1
             vc(0,j,ii) = vb(0,j,ii)*(mu_scale) ;* mub(0,j,ii) * vEta_delta(k)

          end do
       end do
    end if
    
    ;f_final_sens->$A_VAR$ = doubletofloat(vc)
    f_final_sens->$A_VAR$ = vc
    delete(vc)
    delete(vb)
    delete(dsizes)
  end do

  if ( skipped .gt. 0 ) then
    print("Failed to process all variables")
  else
    print("Completed successfully")
  end if

end
